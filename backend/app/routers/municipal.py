import csv
import io
from fastapi import APIRouter, Depends, Query
from fastapi.responses import StreamingResponse
from sqlalchemy import text
from sqlalchemy.orm import Session
from ..db import get_db
from ..municipal_score import ticket_from_counts, tickets_to_csv_rows

router = APIRouter()

PRIORITY_SQL = text("""
    SELECT
        it.crosswalk_id,
        it.city,
        COUNT(*) FILTER (WHERE it.event_type = 'hard_brake') AS hard_brakes,
        COUNT(*) FILTER (WHERE it.event_type = 'occlusion_interrupt') AS occlusions,
        COALESCE(MAX(CASE WHEN mz.zone_type IN ('school', 'hospital') THEN 2.0 ELSE 1.0 END), 1.0) AS zone_multiplier
    FROM incident_telemetry it
    LEFT JOIN crosswalks cw ON it.crosswalk_id = cw.id
    LEFT JOIN municipal_zones mz ON cw.location IS NOT NULL AND ST_DWithin(mz.geom, cw.location, 80)
    WHERE (:city = '' OR it.city ILIKE :city)
    GROUP BY it.crosswalk_id, it.city
""")

def _load_tickets(db, city):
    tickets = []
    for row in db.execute(PRIORITY_SQL, {"city": city}).mappings().all():
        item = ticket_from_counts(row["crosswalk_id"], row["city"], row["hard_brakes"], row["occlusions"], row["zone_multiplier"])
        if item:
            tickets.append(item)
    tickets.sort(key=lambda item: item["calculated_risk_score"], reverse=True)
    return tickets

@router.get("/priority-tickets")
def prioritized_tickets(city: str = Query(""), db: Session = Depends(get_db)) -> dict:
    tickets = _load_tickets(db, city)
    return {"city": city or "all", "total_tickets": len(tickets), "tickets": tickets}

@router.get("/priority-tickets.csv")
def export_prioritized_tickets_csv(city: str = Query(""), db: Session = Depends(get_db)):
    rows = tickets_to_csv_rows(_load_tickets(db, city))
    slug = (city or "all").lower().replace(" ", "_")
    def generate():
        buffer = io.StringIO()
        writer = csv.writer(buffer, dialect="excel")
        for row in rows:
            writer.writerow(row)
            yield buffer.getvalue()
            buffer.seek(0)
            buffer.truncate(0)
    return StreamingResponse(generate(), media_type="text/csv", headers={"Content-Disposition": f"attachment; filename=cross_safe_priority_tickets_{slug}.csv"})
