import uuid
from datetime import datetime

from pydantic import BaseModel, Field

from src.models.group import GroupRole


class GroupCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    description: str | None = None


class GroupUpdate(BaseModel):
    name: str | None = Field(None, min_length=1, max_length=255)
    description: str | None = None
    avatar_url: str | None = None


class MemberOut(BaseModel):
    user_id: uuid.UUID
    full_name: str
    avatar_url: str | None
    role: GroupRole
    joined_at: datetime

    model_config = {"from_attributes": True}


class GroupOut(BaseModel):
    id: uuid.UUID
    name: str
    description: str | None
    avatar_url: str | None
    invite_code: str
    created_by: uuid.UUID
    member_count: int = 0
    my_role: GroupRole | None = None
    created_at: datetime

    model_config = {"from_attributes": True}


class JoinGroupRequest(BaseModel):
    invite_code: str = Field(..., min_length=8, max_length=10)


class UpdateMemberRoleRequest(BaseModel):
    role: GroupRole
