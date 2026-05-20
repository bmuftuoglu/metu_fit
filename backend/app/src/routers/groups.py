import uuid
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from src.database import get_db
from src.dependencies import get_current_user, require_captain, require_dietitian_or_captain
from src.models.group import Group, GroupMember, GroupRole
from src.models.user import User
from src.schemas.group import GroupCreate, GroupUpdate, GroupOut, MemberOut, JoinGroupRequest, UpdateMemberRoleRequest
from src.utils.invite_code import generate_invite_code

router = APIRouter(prefix="/groups", tags=["groups"])

CurrentUser = Annotated[User, Depends(get_current_user)]
DB = Annotated[AsyncSession, Depends(get_db)]


async def _group_out(db: AsyncSession, group: Group, user_id: uuid.UUID) -> GroupOut:
    count_result = await db.execute(
        select(func.count()).where(GroupMember.group_id == group.id)
    )
    member_count = count_result.scalar()

    role_result = await db.execute(
        select(GroupMember.role).where(GroupMember.group_id == group.id, GroupMember.user_id == user_id)
    )
    my_role = role_result.scalar_one_or_none()

    return GroupOut(
        id=group.id,
        name=group.name,
        description=group.description,
        avatar_url=group.avatar_url,
        invite_code=group.invite_code,
        created_by=group.created_by,
        member_count=member_count,
        my_role=my_role,
        created_at=group.created_at,
    )


@router.get("", response_model=list[GroupOut])
async def list_my_groups(db: DB = None, current_user: CurrentUser = None):
    result = await db.execute(
        select(Group)
        .join(GroupMember, GroupMember.group_id == Group.id)
        .where(GroupMember.user_id == current_user.id, Group.deleted_at.is_(None))
        .order_by(Group.created_at.desc())
    )
    groups = result.scalars().all()
    return [await _group_out(db, g, current_user.id) for g in groups]


@router.post("", response_model=GroupOut, status_code=201)
async def create_group(data: GroupCreate, db: DB = None, current_user: CurrentUser = None):
    invite_code = generate_invite_code()
    group = Group(
        name=data.name,
        description=data.description,
        invite_code=invite_code,
        created_by=current_user.id,
    )
    db.add(group)
    await db.flush()

    member = GroupMember(group_id=group.id, user_id=current_user.id, role=GroupRole.captain)
    db.add(member)
    await db.commit()
    await db.refresh(group)
    return await _group_out(db, group, current_user.id)


@router.post("/join", response_model=GroupOut)
async def join_group(data: JoinGroupRequest, db: DB = None, current_user: CurrentUser = None):
    result = await db.execute(
        select(Group).where(Group.invite_code == data.invite_code, Group.deleted_at.is_(None))
    )
    group = result.scalar_one_or_none()
    if not group:
        raise HTTPException(status_code=404, detail="Invalid invite code")

    existing = await db.execute(
        select(GroupMember).where(GroupMember.group_id == group.id, GroupMember.user_id == current_user.id)
    )
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=409, detail="Already a member")

    member = GroupMember(group_id=group.id, user_id=current_user.id, role=GroupRole.member)
    db.add(member)
    await db.commit()
    return await _group_out(db, group, current_user.id)


@router.get("/{group_id}", response_model=GroupOut)
async def get_group(group_id: uuid.UUID, db: DB = None, current_user: CurrentUser = None):
    result = await db.execute(
        select(Group).where(Group.id == group_id, Group.deleted_at.is_(None))
    )
    group = result.scalar_one_or_none()
    if not group:
        raise HTTPException(status_code=404, detail="Group not found")
    return await _group_out(db, group, current_user.id)


@router.patch("/{group_id}", response_model=GroupOut)
async def update_group(
    group_id: uuid.UUID,
    data: GroupUpdate,
    db: DB = None,
    current_user: CurrentUser = None,
    _: GroupMember = Depends(require_captain),
):
    result = await db.execute(select(Group).where(Group.id == group_id))
    group = result.scalar_one_or_none()
    if not group:
        raise HTTPException(status_code=404, detail="Group not found")

    for field, value in data.model_dump(exclude_none=True).items():
        setattr(group, field, value)
    await db.commit()
    await db.refresh(group)
    return await _group_out(db, group, current_user.id)


@router.delete("/{group_id}", status_code=204)
async def delete_group(
    group_id: uuid.UUID,
    db: DB = None,
    _: GroupMember = Depends(require_captain),
):
    from datetime import datetime, timezone
    result = await db.execute(select(Group).where(Group.id == group_id))
    group = result.scalar_one_or_none()
    if group:
        group.deleted_at = datetime.now(timezone.utc)
        await db.commit()


@router.post("/{group_id}/regenerate-invite", response_model=GroupOut)
async def regenerate_invite(
    group_id: uuid.UUID,
    db: DB = None,
    current_user: CurrentUser = None,
    _: GroupMember = Depends(require_captain),
):
    result = await db.execute(select(Group).where(Group.id == group_id))
    group = result.scalar_one()
    group.invite_code = generate_invite_code()
    await db.commit()
    await db.refresh(group)
    return await _group_out(db, group, current_user.id)


@router.get("/{group_id}/members", response_model=list[MemberOut])
async def list_members(
    group_id: uuid.UUID,
    db: DB = None,
    _: User = Depends(get_current_user),
):
    result = await db.execute(
        select(GroupMember, User)
        .join(User, User.id == GroupMember.user_id)
        .where(GroupMember.group_id == group_id)
        .order_by(GroupMember.joined_at)
    )
    rows = result.all()
    return [
        MemberOut(
            user_id=member.user_id,
            full_name=user.full_name,
            avatar_url=user.avatar_url,
            role=member.role,
            joined_at=member.joined_at,
        )
        for member, user in rows
    ]


@router.patch("/{group_id}/members/{user_id}", response_model=MemberOut)
async def update_member_role(
    group_id: uuid.UUID,
    user_id: uuid.UUID,
    data: UpdateMemberRoleRequest,
    db: DB = None,
    _: GroupMember = Depends(require_captain),
):
    result = await db.execute(
        select(GroupMember, User)
        .join(User, User.id == GroupMember.user_id)
        .where(GroupMember.group_id == group_id, GroupMember.user_id == user_id)
    )
    row = result.one_or_none()
    if not row:
        raise HTTPException(status_code=404, detail="Member not found")
    member, user = row
    member.role = data.role
    await db.commit()
    return MemberOut(user_id=member.user_id, full_name=user.full_name, avatar_url=user.avatar_url, role=member.role, joined_at=member.joined_at)


@router.delete("/{group_id}/members/me", status_code=204)
async def leave_group(group_id: uuid.UUID, db: DB = None, current_user: CurrentUser = None):
    result = await db.execute(
        select(GroupMember).where(GroupMember.group_id == group_id, GroupMember.user_id == current_user.id)
    )
    member = result.scalar_one_or_none()
    if not member:
        raise HTTPException(status_code=404, detail="Not a member")
    await db.delete(member)
    await db.commit()


@router.delete("/{group_id}/members/{user_id}", status_code=204)
async def remove_member(
    group_id: uuid.UUID,
    user_id: uuid.UUID,
    db: DB = None,
    _: GroupMember = Depends(require_captain),
):
    result = await db.execute(
        select(GroupMember).where(GroupMember.group_id == group_id, GroupMember.user_id == user_id)
    )
    member = result.scalar_one_or_none()
    if not member:
        raise HTTPException(status_code=404, detail="Member not found")
    await db.delete(member)
    await db.commit()
