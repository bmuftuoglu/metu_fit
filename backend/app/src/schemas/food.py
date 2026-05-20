import uuid
from datetime import date, datetime
from typing import Literal

from pydantic import BaseModel, Field


class FoodItemOut(BaseModel):
    id: uuid.UUID
    name: str
    brand: str | None
    calories_per_100g: float
    protein_g: float | None
    carbs_g: float | None
    fat_g: float | None
    is_custom: bool

    model_config = {"from_attributes": True}


class FoodItemCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    brand: str | None = Field(None, max_length=255)
    calories_per_100g: float = Field(..., gt=0)
    protein_g: float | None = Field(None, ge=0)
    carbs_g: float | None = Field(None, ge=0)
    fat_g: float | None = Field(None, ge=0)


class FoodLogCreate(BaseModel):
    food_item_id: uuid.UUID
    grams: float = Field(..., gt=0)
    meal_type: Literal["breakfast", "lunch", "dinner", "snack"]
    logged_at: date | None = None


class FoodLogOut(BaseModel):
    id: uuid.UUID
    food_item_id: uuid.UUID
    food_item: FoodItemOut
    grams: float
    calories: float
    meal_type: str
    logged_at: date
    created_at: datetime

    model_config = {"from_attributes": True}


class DailySummary(BaseModel):
    date: date
    goal_calories: int | None
    consumed_calories: float
    burned_calories: float
    net_calories: float
    logs: list[FoodLogOut]
