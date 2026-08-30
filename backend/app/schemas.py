from datetime import datetime
from pydantic import BaseModel, Field

class CrosswalkIn(BaseModel):
    name: str
    city: str = "Vitoria"
    state: str = "ES"
    lat: float = Field(..., ge=-90, le=90)
    lon: float = Field(..., ge=-180, le=180)
    risk_score: float = 0.0
    notes: str | None = None

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
    name: str
    zone_type: str
    priority: int = 2
    wkt_polygon: str

class ZoneOut(BaseModel):
    id: int
    name: str
    zone_type: str
    priority: int

class TelemetryIn(BaseModel):
    transport_mode: str
    event_type: str
    lat: float
    lon: float
    speed_mps: float | None = None
    deceleration_mps2: float | None = None
    crosswalk_id: int | None = None
    distance_m: float | None = None
    respect_score: int | None = None
    screen_active: bool | None = None
    mode_confidence: float | None = None
    source: str = "in_app"
    city: str = "Vitoria"
    features: dict | None = None

class TelemetryOut(BaseModel):
    id: int
    transport_mode: str
    event_type: str
    recorded_at: datetime

class NearbyQuery(BaseModel):
    lat: float
    lon: float
    radius_m: float = 250
    speed_mps: float = 0
