from datetime import date, timedelta
from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy import select, func, cast, Float
from sqlalchemy.ext.asyncio import AsyncSession

from src.database import get_db
from src.dependencies import get_current_user
from src.models.user import User
from src.models.food import FoodLog
from src.models.activity import ActivityLog
from src.schemas.user import UserResponse, UpdateProfileRequest, CalorieSummaryResponse

router = APIRouter(prefix="/users", tags=["users"])


@router.get("/me", response_model=UserResponse)
async def get_me(current_user: Annotated[User, Depends(get_current_user)]):
    return current_user


@router.patch("/me", response_model=UserResponse)
async def update_me(
    body: UpdateProfileRequest,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
):
    for field, value in body.model_dump(exclude_none=True).items():
        setattr(current_user, field, value)
    await db.commit()
    await db.refresh(current_user)
    return current_user


@router.get("/me/calorie-summary", response_model=CalorieSummaryResponse)
async def calorie_summary(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
    target_date: date = None,
):
    if not target_date:
        target_date = date.today()

    consumed_result = await db.execute(
        select(func.coalesce(func.sum(FoodLog.calories), 0.0)).where(
            FoodLog.user_id == current_user.id,
            FoodLog.logged_at == target_date,
        )
    )
    consumed = float(consumed_result.scalar())

    burned_result = await db.execute(
        select(func.coalesce(func.sum(ActivityLog.calories_burned), 0.0)).where(
            ActivityLog.user_id == current_user.id,
            func.date(ActivityLog.started_at) == target_date,
        )
    )
    burned = float(burned_result.scalar())

    return CalorieSummaryResponse(
        date=target_date.isoformat(),
        consumed=consumed,
        burned=burned,
        net=consumed - burned,
        goal=current_user.goal_calories,
    )
