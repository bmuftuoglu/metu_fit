from datetime import date, datetime
import uuid

from sqlalchemy import String, Text, Numeric, Boolean, Date, TIMESTAMP, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func

from src.database import Base


class FoodItem(Base):
    __tablename__ = "food_items"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name: Mapped[str] = mapped_column(String(255), nullable=False, index=True)
    brand: Mapped[str | None] = mapped_column(String(255), nullable=True)
    calories_per_100g: Mapped[float] = mapped_column(Numeric(7, 2), nullable=False)
    protein_g: Mapped[float | None] = mapped_column(Numeric(6, 2), nullable=True)
    carbs_g: Mapped[float | None] = mapped_column(Numeric(6, 2), nullable=True)
    fat_g: Mapped[float | None] = mapped_column(Numeric(6, 2), nullable=True)
    is_custom: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    created_by: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    created_at: Mapped[datetime] = mapped_column(TIMESTAMP(timezone=True), server_default=func.now())

    logs: Mapped[list["FoodLog"]] = relationship("FoodLog", back_populates="food_item", lazy="noload")


class FoodLog(Base):
    __tablename__ = "food_logs"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    food_item_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("food_items.id"), nullable=False)
    grams: Mapped[float] = mapped_column(Numeric(7, 2), nullable=False)
    calories: Mapped[float] = mapped_column(Numeric(7, 2), nullable=False)
    meal_type: Mapped[str] = mapped_column(String(20), nullable=False)
    logged_at: Mapped[date] = mapped_column(Date, nullable=False, server_default=func.current_date())
    created_at: Mapped[datetime] = mapped_column(TIMESTAMP(timezone=True), server_default=func.now())

    food_item: Mapped["FoodItem"] = relationship("FoodItem", back_populates="logs", lazy="noload")
