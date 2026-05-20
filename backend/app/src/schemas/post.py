import uuid
from datetime import datetime
from typing import Any

from pydantic import BaseModel, Field

from src.models.post import PostType


class AuthorOut(BaseModel):
    id: uuid.UUID
    full_name: str
    avatar_url: str | None

    model_config = {"from_attributes": True}


class MealPostCreate(BaseModel):
    description: str | None = None
    image_url: str | None = None
    calories: float = Field(..., gt=0)


class ActivityPostCreate(BaseModel):
    description: str | None = None
    image_url: str | None = None
    activity_log_id: uuid.UUID | None = None
    duration_seconds: int = Field(..., gt=0)
    calories_burned: float = Field(..., ge=0)
    route_snapshot: list[Any] | None = None


class CommentCreate(BaseModel):
    content: str = Field(..., min_length=1, max_length=1000)


class CommentOut(BaseModel):
    id: uuid.UUID
    author: AuthorOut
    content: str
    created_at: datetime

    model_config = {"from_attributes": True}


class PostOut(BaseModel):
    id: uuid.UUID
    group_id: uuid.UUID
    post_type: PostType
    author: AuthorOut
    description: str | None
    image_url: str | None
    like_count: int = 0
    comment_count: int = 0
    is_liked: bool = False
    calories: float | None = None
    duration_seconds: int | None = None
    calories_burned: float | None = None
    route_snapshot: list[Any] | None = None
    activity_log_id: uuid.UUID | None = None
    created_at: datetime

    model_config = {"from_attributes": True}


class PostPage(BaseModel):
    items: list[PostOut]
    next_cursor: str | None
