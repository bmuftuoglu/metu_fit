import uuid
from base64 import b64encode, b64decode
from datetime import datetime, timezone
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select, func, and_
from sqlalchemy.ext.asyncio import AsyncSession

from src.database import get_db
from src.dependencies import get_current_user
from src.models.group import Group, GroupMember
from src.models.post import Post, MealPost, ActivityPost, Like, Comment, PostType
from src.models.user import User
from src.schemas.post import (
    MealPostCreate, ActivityPostCreate, CommentCreate,
    PostOut, PostPage, CommentOut, AuthorOut,
)

router = APIRouter(tags=["posts"])

CurrentUser = Annotated[User, Depends(get_current_user)]
DB = Annotated[AsyncSession, Depends(get_db)]


async def _assert_member(db: AsyncSession, group_id: uuid.UUID, user_id: uuid.UUID) -> GroupMember:
    result = await db.execute(
        select(GroupMember).where(GroupMember.group_id == group_id, GroupMember.user_id == user_id)
    )
    member = result.scalar_one_or_none()
    if not member:
        raise HTTPException(status_code=403, detail="Not a group member")
    return member


async def _build_post_out(db: AsyncSession, post: Post, current_user_id: uuid.UUID) -> PostOut:
    author_result = await db.execute(select(User).where(User.id == post.author_id))
    author = author_result.scalar_one()

    like_count_result = await db.execute(
        select(func.count()).where(Like.post_id == post.id)
    )
    like_count = like_count_result.scalar()

    comment_count_result = await db.execute(
        select(func.count()).where(Comment.post_id == post.id, Comment.deleted_at.is_(None))
    )
    comment_count = comment_count_result.scalar()

    is_liked_result = await db.execute(
        select(Like).where(Like.post_id == post.id, Like.user_id == current_user_id)
    )
    is_liked = is_liked_result.scalar_one_or_none() is not None

    calories = None
    duration_seconds = None
    calories_burned = None
    route_snapshot = None
    activity_log_id = None

    if post.post_type == PostType.meal:
        ext_result = await db.execute(select(MealPost).where(MealPost.id == post.id))
        ext = ext_result.scalar_one_or_none()
        if ext:
            calories = float(ext.calories)
    else:
        ext_result = await db.execute(select(ActivityPost).where(ActivityPost.id == post.id))
        ext = ext_result.scalar_one_or_none()
        if ext:
            duration_seconds = ext.duration_seconds
            calories_burned = float(ext.calories_burned)
            route_snapshot = ext.route_snapshot
            activity_log_id = ext.activity_log_id

    return PostOut(
        id=post.id,
        group_id=post.group_id,
        post_type=post.post_type,
        author=AuthorOut(id=author.id, full_name=author.full_name, avatar_url=author.avatar_url),
        description=post.description,
        image_url=post.image_url,
        like_count=like_count,
        comment_count=comment_count,
        is_liked=is_liked,
        calories=calories,
        duration_seconds=duration_seconds,
        calories_burned=calories_burned,
        route_snapshot=route_snapshot,
        activity_log_id=activity_log_id,
        created_at=post.created_at,
    )


@router.get("/groups/{group_id}/posts", response_model=PostPage)
async def get_group_feed(
    group_id: uuid.UUID,
    cursor: str | None = Query(None),
    limit: int = Query(20, le=50),
    db: DB = None,
    current_user: CurrentUser = None,
):
    await _assert_member(db, group_id, current_user.id)

    stmt = (
        select(Post)
        .where(Post.group_id == group_id, Post.deleted_at.is_(None))
        .order_by(Post.created_at.desc())
        .limit(limit + 1)
    )
    if cursor:
        try:
            cursor_dt = datetime.fromisoformat(b64decode(cursor).decode())
            stmt = stmt.where(Post.created_at < cursor_dt)
        except Exception:
            pass

    result = await db.execute(stmt)
    posts = list(result.scalars().all())

    next_cursor = None
    if len(posts) > limit:
        posts = posts[:limit]
        next_cursor = b64encode(posts[-1].created_at.isoformat().encode()).decode()

    items = [await _build_post_out(db, p, current_user.id) for p in posts]
    return PostPage(items=items, next_cursor=next_cursor)


@router.post("/groups/{group_id}/posts/meal", response_model=PostOut, status_code=201)
async def create_meal_post(
    group_id: uuid.UUID,
    data: MealPostCreate,
    db: DB = None,
    current_user: CurrentUser = None,
):
    await _assert_member(db, group_id, current_user.id)
    post = Post(group_id=group_id, author_id=current_user.id, post_type=PostType.meal,
                description=data.description, image_url=data.image_url)
    db.add(post)
    await db.flush()
    db.add(MealPost(id=post.id, calories=data.calories))
    await db.commit()
    await db.refresh(post)
    return await _build_post_out(db, post, current_user.id)


@router.post("/groups/{group_id}/posts/activity", response_model=PostOut, status_code=201)
async def create_activity_post(
    group_id: uuid.UUID,
    data: ActivityPostCreate,
    db: DB = None,
    current_user: CurrentUser = None,
):
    await _assert_member(db, group_id, current_user.id)
    post = Post(group_id=group_id, author_id=current_user.id, post_type=PostType.activity,
                description=data.description, image_url=data.image_url)
    db.add(post)
    await db.flush()
    db.add(ActivityPost(
        id=post.id,
        activity_log_id=data.activity_log_id,
        duration_seconds=data.duration_seconds,
        calories_burned=data.calories_burned,
        route_snapshot=data.route_snapshot,
    ))
    await db.commit()
    await db.refresh(post)
    return await _build_post_out(db, post, current_user.id)


@router.delete("/groups/{group_id}/posts/{post_id}", status_code=204)
async def delete_post(
    group_id: uuid.UUID,
    post_id: uuid.UUID,
    db: DB = None,
    current_user: CurrentUser = None,
):
    result = await db.execute(
        select(Post).where(Post.id == post_id, Post.group_id == group_id, Post.deleted_at.is_(None))
    )
    post = result.scalar_one_or_none()
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")

    member_result = await db.execute(
        select(GroupMember).where(GroupMember.group_id == group_id, GroupMember.user_id == current_user.id)
    )
    member = member_result.scalar_one_or_none()
    if post.author_id != current_user.id and (not member or member.role not in ("captain", "dietitian")):
        raise HTTPException(status_code=403, detail="Forbidden")

    post.deleted_at = datetime.now(timezone.utc)
    await db.commit()


@router.post("/posts/{post_id}/likes", status_code=201)
async def like_post(post_id: uuid.UUID, db: DB = None, current_user: CurrentUser = None):
    existing = await db.execute(select(Like).where(Like.post_id == post_id, Like.user_id == current_user.id))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=409, detail="Already liked")
    db.add(Like(post_id=post_id, user_id=current_user.id))
    await db.commit()
    return {"liked": True}


@router.delete("/posts/{post_id}/likes", status_code=204)
async def unlike_post(post_id: uuid.UUID, db: DB = None, current_user: CurrentUser = None):
    result = await db.execute(select(Like).where(Like.post_id == post_id, Like.user_id == current_user.id))
    like = result.scalar_one_or_none()
    if not like:
        raise HTTPException(status_code=404, detail="Not liked")
    await db.delete(like)
    await db.commit()


@router.get("/posts/{post_id}/comments", response_model=list[CommentOut])
async def list_comments(post_id: uuid.UUID, db: DB = None, _: CurrentUser = None):
    result = await db.execute(
        select(Comment, User)
        .join(User, User.id == Comment.author_id)
        .where(Comment.post_id == post_id, Comment.deleted_at.is_(None))
        .order_by(Comment.created_at)
    )
    rows = result.all()
    return [
        CommentOut(
            id=comment.id,
            author=AuthorOut(id=user.id, full_name=user.full_name, avatar_url=user.avatar_url),
            content=comment.content,
            created_at=comment.created_at,
        )
        for comment, user in rows
    ]


@router.post("/posts/{post_id}/comments", response_model=CommentOut, status_code=201)
async def add_comment(post_id: uuid.UUID, data: CommentCreate, db: DB = None, current_user: CurrentUser = None):
    comment = Comment(post_id=post_id, author_id=current_user.id, content=data.content)
    db.add(comment)
    await db.commit()
    await db.refresh(comment)
    return CommentOut(
        id=comment.id,
        author=AuthorOut(id=current_user.id, full_name=current_user.full_name, avatar_url=current_user.avatar_url),
        content=comment.content,
        created_at=comment.created_at,
    )


@router.delete("/posts/{post_id}/comments/{comment_id}", status_code=204)
async def delete_comment(
    post_id: uuid.UUID,
    comment_id: uuid.UUID,
    db: DB = None,
    current_user: CurrentUser = None,
):
    result = await db.execute(
        select(Comment).where(Comment.id == comment_id, Comment.post_id == post_id, Comment.deleted_at.is_(None))
    )
    comment = result.scalar_one_or_none()
    if not comment:
        raise HTTPException(status_code=404, detail="Comment not found")
    if comment.author_id != current_user.id:
        raise HTTPException(status_code=403, detail="Forbidden")
    comment.deleted_at = datetime.now(timezone.utc)
    await db.commit()
