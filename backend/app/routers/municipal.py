from fastapi import APIRouter, Depends, Query
from sqlalchemy import text
from sqlalchemy.orm import Session
from ..db import get_db
from ..municipal_score import classify_risk, risk_score

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
    LEFT JOIN municipal_zones mz
        ON cw.location IS NOT NULL
       AND ST_DWithin(mz.geom, cw.location, 80)
    WHERE (:city = '' OR it.city ILIKE :city)
    GROUP BY it.crosswalk_id, it.city
""")

@router.get("/priority-tickets")
def prioritized_tickets(city: str = Query(""), db: Session = Depends(get_db)) -> dict:
    rows = db.execute(PRIORITY_SQL, {"city": city}).mappings().all()
    tickets = []
    for row in rows:
        multiplier = float(row["zone_multiplier"] or 1.0)
        score = risk_score(int(row["hard_brakes"] or 0), int(row["occlusions"] or 0), multiplier)
        ranked = classify_risk(score, multiplier)
        if ranked is None:
            continue
        level, justification = ranked
        tickets.append({
            "crosswalk_id": row["crosswalk_id"],
            "city": row["city"],
            "metrics": {"hard_brakes": int(row["hard_brakes"] or 0), "occlusions": int(row["occlusions"] or 0)},
            "priority_level": level,
            "calculated_risk_score": round(score, 2),
            "zone_multiplier": multiplier,
            "dispatch_justification": justification,
        })
    tickets.sort(key=lambda item: item["calculated_risk_score"], reverse=True)
    return {"city": city or "all", "total_tickets": len(tickets), "tickets": tickets}
