from datetime import datetime
from geoalchemy2 import Geography
from sqlalchemy import Boolean, DateTime, Float, ForeignKey, Integer, String, Text, func
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column

class Base(DeclarativeBase):
    pass

class Crosswalk(Base):
    __tablename__ = "crosswalks"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    name: Mapped[str] = mapped_column(String(160), nullable=False)
    city: Mapped[str] = mapped_column(String(80), nullable=False, default="Vitoria")
    state: Mapped[str] = mapped_column(String(2), nullable=False, default="ES")
    risk_score: Mapped[float] = mapped_column(Float, nullable=False, default=0.0)
    location = mapped_column(Geography(geometry_type="POINT", srid=4326), nullable=False)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

class MunicipalZone(Base):
    __tablename__ = "municipal_zones"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    name: Mapped[str] = mapped_column(String(160), nullable=False)
    zone_type: Mapped[str] = mapped_column(String(40), nullable=False)
    priority: Mapped[int] = mapped_column(Integer, nullable=False, default=2)
    geom = mapped_column(Geography(geometry_type="POLYGON", srid=4326), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

class IncidentTelemetry(Base):
    __tablename__ = "incident_telemetry"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    transport_mode: Mapped[str] = mapped_column(String(32), nullable=False)
    event_type: Mapped[str] = mapped_column(String(40), nullable=False)
    speed_mps: Mapped[float | None] = mapped_column(Float, nullable=True)
    deceleration_mps2: Mapped[float | None] = mapped_column(Float, nullable=True)
    location = mapped_column(Geography(geometry_type="POINT", srid=4326), nullable=False)
    crosswalk_id: Mapped[int | None] = mapped_column(ForeignKey("crosswalks.id"), nullable=True)
    distance_m: Mapped[float | None] = mapped_column(Float, nullable=True)
    respect_score: Mapped[int | None] = mapped_column(Integer, nullable=True)
    screen_active: Mapped[bool | None] = mapped_column(Boolean, nullable=True)
    mode_confidence: Mapped[float | None] = mapped_column(Float, nullable=True)
    source: Mapped[str] = mapped_column(String(24), nullable=False, default="in_app")
    city: Mapped[str] = mapped_column(String(80), nullable=False, default="Vitoria")
    features_json: Mapped[str | None] = mapped_column(Text, nullable=True)
    recorded_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
