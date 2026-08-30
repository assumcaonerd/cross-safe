import json
from fastapi import APIRouter, Depends, HTTPException, Query
from geoalchemy2.functions import ST_DWithin, ST_MakePoint, ST_SetSRID, ST_X, ST_Y
from sqlalchemy import select, func as sqlfunc
from sqlalchemy.orm import Session
from ..config import settings
from ..db import get_db
from ..geo import braking_distance_m
from ..models import Crosswalk, IncidentTelemetry, MunicipalZone
from ..schemas import (
    CrosswalkIn, CrosswalkOut, NearbyQuery, TelemetryIn, PriorityTicket,
    TelemetryOut, ZoneIn, ZoneOut,
)

router = APIRouter()

def _point(lon: float, lat: float):
    return ST_SetSRID(ST_MakePoint(lon, lat), 4326)

@router.post("/crosswalks", response_model=CrosswalkOut, status_code=201)
def create_crosswalk(payload: CrosswalkIn, db: Session = Depends(get_db)) -> CrosswalkOut:
    row = Crosswalk(name=payload.name, city=payload.city, state=payload.state, risk_score=payload.risk_score, notes=payload.notes, location=_point(payload.lon, payload.lat))
    db.add(row); db.commit(); db.refresh(row)
    return CrosswalkOut(id=row.id, name=row.name, city=row.city, state=row.state, lat=payload.lat, lon=payload.lon, risk_score=row.risk_score, notes=row.notes)

@router.get("/crosswalks/nearby", response_model=list[CrosswalkOut])
def nearby_crosswalks(lat: float = Query(..., ge=-90, le=90), lon: float = Query(..., ge=-180, le=180), radius_m: float = Query(250, gt=0), speed_mps: float = Query(0, ge=0), db: Session = Depends(get_db)) -> list[CrosswalkOut]:
    radius = min(radius_m, settings.max_search_radius_m)
    if speed_mps > 0:
        radius = max(radius, braking_distance_m(speed_mps) + 40)
    origin = _point(lon, lat)
    stmt = select(Crosswalk, ST_Y(Crosswalk.location).label("lat"), ST_X(Crosswalk.location).label("lon")).where(ST_DWithin(Crosswalk.location, origin, radius)).limit(50)
    from ..geo import haversine_m
    out = []
    for row, plat, plon in db.execute(stmt).all():
        out.append(CrosswalkOut(id=row.id, name=row.name, city=row.city, state=row.state, lat=float(plat), lon=float(plon), risk_score=row.risk_score, distance_m=round(haversine_m(lat, lon, float(plat), float(plon)), 1), notes=row.notes))
    out.sort(key=lambda item: item.distance_m or 0)
    return out

@router.post("/zones", response_model=ZoneOut, status_code=201)
def create_zone(payload: ZoneIn, db: Session = Depends(get_db)) -> ZoneOut:
    from geoalchemy2.elements import WKTElement
    row = MunicipalZone(name=payload.name, zone_type=payload.zone_type, priority=payload.priority, geom=WKTElement(payload.wkt_polygon, srid=4326))
    db.add(row); db.commit(); db.refresh(row)
    return ZoneOut(id=row.id, name=row.name, zone_type=row.zone_type, priority=row.priority)

@router.post("/telemetry", response_model=TelemetryOut, status_code=201)
def ingest_telemetry(payload: TelemetryIn, db: Session = Depends(get_db)) -> TelemetryOut:
    if payload.crosswalk_id:
        if not db.get(Crosswalk, payload.crosswalk_id):
            raise HTTPException(status_code=404, detail="crosswalk not found")
    row = IncidentTelemetry(
        transport_mode=payload.transport_mode,
        event_type=payload.event_type,
        speed_mps=payload.speed_mps,
        deceleration_mps2=payload.deceleration_mps2,
        location=_point(payload.lon, payload.lat),
        crosswalk_id=payload.crosswalk_id,
        distance_m=payload.distance_m,
        respect_score=payload.respect_score,
        screen_active=payload.screen_active,
        mode_confidence=payload.mode_confidence,
        source=payload.source,
        city=payload.city,
        features_json=json.dumps(payload.features or {}),
    )
    db.add(row); db.commit(); db.refresh(row)
    return TelemetryOut(id=row.id, transport_mode=row.transport_mode, event_type=row.event_type, recorded_at=row.recorded_at, source=row.source, distance_m=row.distance_m, city=row.city)

@router.get("/municipal/priority-tickets", response_model=list[PriorityTicket])
def municipal_priority_tickets(db: Session = Depends(get_db)) -> list[PriorityTicket]:
    stmt = (
        select(IncidentTelemetry.crosswalk_id, IncidentTelemetry.city, IncidentTelemetry.event_type, sqlfunc.count().label("hits"))
        .where(IncidentTelemetry.event_type.in_(("hard_brake", "occlusion_interrupt", "driver_interrupt")))
        .group_by(IncidentTelemetry.crosswalk_id, IncidentTelemetry.city, IncidentTelemetry.event_type)
    )
    tickets = []
    for crosswalk_id, city, event_type, hits in db.execute(stmt).all():
        level = 1 if event_type in {"hard_brake", "occlusion_interrupt"} and hits >= 3 else 2
        tickets.append(PriorityTicket(crosswalk_id=crosswalk_id, city=city, event_type=event_type, hits=hits, level=level))
    tickets.sort(key=lambda item: (item.level, -item.hits))
    return tickets

@router.post("/geofence/preview")
def preview_window(payload: NearbyQuery) -> dict:
    window = braking_distance_m(payload.speed_mps)
    return {"lat": payload.lat, "lon": payload.lon, "speed_mps": payload.speed_mps, "alert_distance_m": round(window + 40, 1), "search_radius_m": min(max(payload.radius_m, window + 40), settings.max_search_radius_m)}
