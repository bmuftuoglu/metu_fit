from datetime import datetime
import uuid

from sqlalchemy import String, Integer, Numeric, TIMESTAMP, ForeignKey, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.sql import func

from src.database import Base


class ActivityLog(Base):
    __tablename__ = "activity_logs"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    activity_type: Mapped[str] = mapped_column(String(50), nullable=False)
    started_at: Mapped[datetime] = mapped_column(TIMESTAMP(timezone=True), nullable=False)
    ended_at: Mapped[datetime] = mapped_column(TIMESTAMP(timezone=True), nullable=False)
    duration_seconds: Mapped[int] = mapped_column(Integer, nullable=False)
    distance_meters: Mapped[float | None] = mapped_column(Numeric(10, 2), nullable=True)
    calories_burned: Mapped[float | None] = mapped_column(Numeric(7, 2), nullable=True)
    avg_speed_kmh: Mapped[float | None] = mapped_column(Numeric(6, 2), nullable=True)
    created_at: Mapped[datetime] = mapped_column(TIMESTAMP(timezone=True), server_default=func.now())


class ActivityRoute(Base):
    __tablename__ = "activity_routes"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    activity_log_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("activity_logs.id", ondelete="CASCADE"), nullable=False, unique=True)
    route_points: Mapped[list] = mapped_column(JSONB, nullable=False, default=list)
    bbox_north: Mapped[float | None] = mapped_column(Numeric(10, 7), nullable=True)
    bbox_south: Mapped[float | None] = mapped_column(Numeric(10, 7), nullable=True)
    bbox_east: Mapped[float | None] = mapped_column(Numeric(10, 7), nullable=True)
    bbox_west: Mapped[float | None] = mapped_column(Numeric(10, 7), nullable=True)
    created_at: Mapped[datetime] = mapped_column(TIMESTAMP(timezone=True), server_default=func.now())
