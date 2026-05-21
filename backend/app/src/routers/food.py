import uuid
from datetime import date
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession

from src.database import get_db
from src.dependencies import get_current_user
from src.models.user import User
from src.schemas.food import FoodItemOut, FoodItemCreate, FoodLogCreate, FoodLogOut, DailySummary
from src.services import food_service

router = APIRouter(prefix="/food", tags=["food"])

CurrentUser = Annotated[User, Depends(get_current_user)]
DB = Annotated[AsyncSession, Depends(get_db)]


@router.get("/items", response_model=list[FoodItemOut])
async def search_food_items(
    q: str = Query(..., min_length=1),
    db: DB = None,
    _: CurrentUser = None,
):
    return await food_service.search_food_items(db, q)


@router.post("/items", response_model=FoodItemOut, status_code=201)
async def create_food_item(
    data: FoodItemCreate,
    db: DB = None,
    current_user: CurrentUser = None,
):
    return await food_service.create_food_item(db, data, current_user.id)


@router.get("/logs", response_model=DailySummary)
async def get_daily_logs(
    date_: date = Query(default_factory=date.today, alias="date"),
    db: DB = None,
    current_user: CurrentUser = None,
):
    return await food_service.get_daily_summary(db, current_user, date_)


@router.post("/logs", response_model=FoodLogOut, status_code=201)
async def add_food_log(
    data: FoodLogCreate,
    db: DB = None,
    current_user: CurrentUser = None,
):
    log = await food_service.create_food_log(db, data, current_user.id)
    return log


@router.delete("/logs/{log_id}", status_code=204)
async def delete_food_log(
    log_id: uuid.UUID,
    db: DB = None,
    current_user: CurrentUser = None,
):
    deleted = await food_service.delete_food_log(db, log_id, current_user.id)
    if not deleted:
        raise HTTPException(status_code=404, detail="Log not found")
