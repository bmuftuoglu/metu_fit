from datetime import datetime
import uuid
from pydantic import BaseModel, EmailStr


class UserResponse(BaseModel):
    id: uuid.UUID
    email: EmailStr
    full_name: str
    avatar_url: str | None
    height_cm: float | None
    weight_kg: float | None
    age: int | None
    goal_calories: int | None
    created_at: datetime

    model_config = {"from_attributes": True}


class UpdateProfileRequest(BaseModel):
    full_name: str | None = None
    avatar_url: str | None = None
    height_cm: float | None = None
    weight_kg: float | None = None
    age: int | None = None
    goal_calories: int | None = None


class CalorieSummaryResponse(BaseModel):
    date: str
    consumed: float
    burned: float
    net: float
    goal: int | None
