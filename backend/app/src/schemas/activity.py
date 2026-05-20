import uuid
from datetime import datetime
from typing import Any

from pydantic import BaseModel, Field


class RoutePoint(BaseModel):
    lat: float
    lng: float
    timestamp: datetime | None = None
    altitude: float | None = None


class ActivityLogCreate(BaseModel):
    activity_type: str = Field(..., min_length=1, max_length=50)
    started_at: datetime
    ended_at: datetime
    duration_seconds: int = Field(..., gt=0)
    distance_meters: float | None = Field(None, ge=0)
    calories_burned: float | None = Field(None, ge=0)
    avg_speed_kmh: float | None = Field(None, ge=0)
    route_points: list[RoutePoint] | None = None


class ActivityRouteOut(BaseModel):
    route_points: list[Any]
    bbox_north: float | None
    bbox_south: float | None
    bbox_east: float | None
    bbox_west: float | None

    model_config = {"from_attributes": True}


class ActivityLogOut(BaseModel):
    id: uuid.UUID
    activity_type: str
    started_at: datetime
    ended_at: datetime
    duration_seconds: int
    distance_meters: float | None
    calories_burned: float | None
    avg_speed_kmh: float | None
    route: ActivityRouteOut | None = None
    created_at: datetime

    model_config = {"from_attributes": True}
