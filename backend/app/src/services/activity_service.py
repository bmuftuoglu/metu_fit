import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from src.models.activity import ActivityLog, ActivityRoute
from src.models.user import User
from src.schemas.activity import ActivityLogCreate

MET_VALUES: dict[str, float] = {
    "running": 9.8,
    "walking": 3.5,
    "cycling": 7.5,
    "swimming": 8.0,
    "rowing": 7.0,
    "hiking": 6.0,
    "jump_rope": 12.3,
    "yoga": 3.0,
    "weight_training": 5.0,
    "other": 5.0,
}


def estimate_calories(activity_type: str, weight_kg: float, duration_seconds: int) -> float:
    met = MET_VALUES.get(activity_type, 5.0)
    hours = duration_seconds / 3600
    return round(met * weight_kg * hours, 2)


async def create_activity_log(
    db: AsyncSession,
    data: ActivityLogCreate,
    user: User,
) -> ActivityLog:
    calories = data.calories_burned
    if calories is None and user.weight_kg:
        calories = estimate_calories(data.activity_type, float(user.weight_kg), data.duration_seconds)

    log = ActivityLog(
        user_id=user.id,
        activity_type=data.activity_type,
        started_at=data.started_at,
        ended_at=data.ended_at,
        duration_seconds=data.duration_seconds,
        distance_meters=data.distance_meters,
        calories_burned=calories,
        avg_speed_kmh=data.avg_speed_kmh,
    )
    db.add(log)
    await db.flush()

    if data.route_points:
        points = [p.model_dump() for p in data.route_points]
        lats = [p["lat"] for p in points]
        lngs = [p["lng"] for p in points]
        route = ActivityRoute(
            activity_log_id=log.id,
            route_points=points,
            bbox_north=max(lats),
            bbox_south=min(lats),
            bbox_east=max(lngs),
            bbox_west=min(lngs),
        )
        db.add(route)

    await db.commit()
    await db.refresh(log)
    return log


async def get_activity_logs(db: AsyncSession, user_id: uuid.UUID, limit: int = 20, offset: int = 0) -> list[ActivityLog]:
    stmt = (
        select(ActivityLog)
        .options(selectinload(ActivityLog.route))
        .where(ActivityLog.user_id == user_id)
        .order_by(ActivityLog.started_at.desc())
        .limit(limit)
        .offset(offset)
    )
    result = await db.execute(stmt)
    return list(result.scalars().all())


async def get_activity_log(db: AsyncSession, log_id: uuid.UUID, user_id: uuid.UUID) -> ActivityLog | None:
    stmt = (
        select(ActivityLog)
        .options(selectinload(ActivityLog.route))
        .where(ActivityLog.id == log_id, ActivityLog.user_id == user_id)
    )
    result = await db.execute(stmt)
    return result.scalar_one_or_none()


async def delete_activity_log(db: AsyncSession, log_id: uuid.UUID, user_id: uuid.UUID) -> bool:
    result = await db.execute(
        select(ActivityLog).where(ActivityLog.id == log_id, ActivityLog.user_id == user_id)
    )
    log = result.scalar_one_or_none()
    if not log:
        return False
    await db.delete(log)
    await db.commit()
    return True
