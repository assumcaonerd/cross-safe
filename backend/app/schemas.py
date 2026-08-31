from datetime import datetime

from pydantic import BaseModel, Field


class CrosswalkIn(BaseModel):
    name: str = Field(min_length=2, max_length=160)
    city: str = Field(default="Vitoria", min_length=2, max_length=80)
    state: str = Field(default="ES", min_length=2, max_length=2)
    lat: float = Field(..., ge=-90, le=90)
    lon: float = Field(..., ge=-180, le=180)
    risk_score: float = Field(default=0.0, ge=0)
    notes: str | None = Field(default=None, max_length=2000)


class CrosswalkOut(BaseModel):
    id: int
    name: str
    city: str
    state: str
    lat: float
    lon: float
    risk_score: float
    distance_m: float | None = None
    notes: str | None = None


class ZoneIn(BaseModel):
    name: str = Field(min_length=2, max_length=160)
    zone_type: str = Field(min_length=2, max_length=40)
    priority: int = Field(default=2, ge=1, le=5)
    wkt_polygon: str = Field(min_length=16, max_length=20000)


class ZoneOut(BaseModel):
    id: int
    name: str
    zone_type: str
    priority: int


class TelemetryIn(BaseModel):
    transport_mode: str = Field(min_length=2, max_length=32)
    event_type: str = Field(min_length=2, max_length=40)
    lat: float = Field(..., ge=-90, le=90)
    lon: float = Field(..., ge=-180, le=180)
    speed_mps: float | None = Field(default=None, ge=0, le=120)
    deceleration_mps2: float | None = Field(default=None, ge=-60, le=60)
    crosswalk_id: int | None = Field(default=None, ge=1)
    distance_m: float | None = Field(default=None, ge=0, le=10000)
    respect_score: int | None = Field(default=None, ge=0, le=100)
    screen_active: bool | None = None
    mode_confidence: float | None = Field(default=None, ge=0, le=1)
    source: str = Field(default="in_app", min_length=2, max_length=24)
    city: str = Field(default="Vitoria", min_length=2, max_length=80)
    features: dict | None = None


class TelemetryOut(BaseModel):
    id: int
    transport_mode: str
    event_type: str
    recorded_at: datetime
    source: str = "in_app"
    distance_m: float | None = None
    city: str | None = None


class NearbyQuery(BaseModel):
    lat: float = Field(..., ge=-90, le=90)
    lon: float = Field(..., ge=-180, le=180)
    radius_m: float = Field(default=250, gt=0, le=10000)
    speed_mps: float = Field(default=0, ge=0, le=120)
