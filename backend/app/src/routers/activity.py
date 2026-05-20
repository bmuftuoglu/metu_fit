import uuid
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession

from src.database import get_db
from src.dependencies import get_current_user
from src.models.user import User
from src.schemas.activity import ActivityLogCreate, ActivityLogOut
from src.services import activity_service

router = APIRouter(prefix="/activities", tags=["activities"])

CurrentUser = Annotated[User, Depends(get_current_user)]
DB = Annotated[AsyncSession, Depends(get_db)]


@router.get("", response_model=list[ActivityLogOut])
async def list_activity_logs(
    limit: int = Query(20, le=50),
    offset: int = Query(0, ge=0),
    db: DB = None,
    current_user: CurrentUser = None,
):
    return await activity_service.get_activity_logs(db, current_user.id, limit, offset)


@router.post("", response_model=ActivityLogOut, status_code=201)
async def create_activity_log(
    data: ActivityLogCreate,
    db: DB = None,
    current_user: CurrentUser = None,
):
    return await activity_service.create_activity_log(db, data, current_user)


@router.get("/{log_id}", response_model=ActivityLogOut)
async def get_activity_log(
    log_id: uuid.UUID,
    db: DB = None,
    current_user: CurrentUser = None,
):
    log = await activity_service.get_activity_log(db, log_id, current_user.id)
    if not log:
        raise HTTPException(status_code=404, detail="Activity not found")
    return log


@router.delete("/{log_id}", status_code=204)
async def delete_activity_log(
    log_id: uuid.UUID,
    db: DB = None,
    current_user: CurrentUser = None,
):
    deleted = await activity_service.delete_activity_log(db, log_id, current_user.id)
    if not deleted:
        raise HTTPException(status_code=404, detail="Activity not found")
