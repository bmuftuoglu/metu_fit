import uuid
from datetime import date

from sqlalchemy import select, func, and_
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from src.models.food import FoodItem, FoodLog
from src.models.activity import ActivityLog
from src.models.user import User
from src.schemas.food import FoodItemCreate, FoodLogCreate, DailySummary, FoodLogOut


async def search_food_items(db: AsyncSession, query: str, limit: int = 20) -> list[FoodItem]:
    stmt = (
        select(FoodItem)
        .where(FoodItem.name.ilike(f"%{query}%"))
        .order_by(FoodItem.is_custom, FoodItem.name)
        .limit(limit)
    )
    result = await db.execute(stmt)
    return list(result.scalars().all())


async def create_food_item(db: AsyncSession, data: FoodItemCreate, user_id: uuid.UUID) -> FoodItem:
    item = FoodItem(
        **data.model_dump(),
        is_custom=True,
        created_by=user_id,
    )
    db.add(item)
    await db.commit()
    await db.refresh(item)
    return item


async def create_food_log(db: AsyncSession, data: FoodLogCreate, user_id: uuid.UUID) -> FoodLog:
    item_result = await db.execute(select(FoodItem).where(FoodItem.id == data.food_item_id))
    food_item = item_result.scalar_one_or_none()
    if not food_item:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="Food item not found")

    calories = round(food_item.calories_per_100g * data.grams / 100, 2)
    log = FoodLog(
        user_id=user_id,
        food_item_id=data.food_item_id,
        grams=data.grams,
        calories=calories,
        meal_type=data.meal_type,
        logged_at=data.logged_at or date.today(),
    )
    db.add(log)
    await db.commit()
    await db.refresh(log)
    return log


async def get_daily_logs(db: AsyncSession, user_id: uuid.UUID, day: date) -> list[FoodLog]:
    stmt = (
        select(FoodLog)
        .options(selectinload(FoodLog.food_item))
        .where(FoodLog.user_id == user_id, FoodLog.logged_at == day)
        .order_by(FoodLog.created_at)
    )
    result = await db.execute(stmt)
    return list(result.scalars().all())


async def delete_food_log(db: AsyncSession, log_id: uuid.UUID, user_id: uuid.UUID) -> bool:
    result = await db.execute(
        select(FoodLog).where(FoodLog.id == log_id, FoodLog.user_id == user_id)
    )
    log = result.scalar_one_or_none()
    if not log:
        return False
    await db.delete(log)
    await db.commit()
    return True


async def get_daily_summary(db: AsyncSession, user: User, day: date) -> DailySummary:
    logs = await get_daily_logs(db, user.id, day)

    consumed = sum(float(log.calories) for log in logs)

    burned_result = await db.execute(
        select(func.coalesce(func.sum(ActivityLog.calories_burned), 0)).where(
            and_(
                ActivityLog.user_id == user.id,
                func.date(ActivityLog.started_at) == day,
                ActivityLog.calories_burned.isnot(None),
            )
        )
    )
    burned = float(burned_result.scalar())

    from src.schemas.food import FoodLogOut as FoodLogOutSchema
    log_items = []
    for log in logs:
        log_items.append(FoodLogOut.model_validate(log))

    return DailySummary(
        date=day,
        goal_calories=user.goal_calories,
        consumed_calories=consumed,
        burned_calories=burned,
        net_calories=consumed - burned,
        logs=log_items,
    )
