WEIGHT_HARD_BRAKE = 1.5
WEIGHT_OCCLUSION = 1.0
CRITICAL_ZONE_TYPES = frozenset({"school", "hospital"})
CRITICAL_MULTIPLIER = 2.0
CRITICAL_THRESHOLD = 5.0
CSV_HEADER = ["crosswalk_id", "city", "hard_brakes_count", "occlusions_count", "zone_multiplier", "calculated_risk_score", "priority_level"]

def zone_multiplier(zone_type):
    return 2.0 if zone_type in CRITICAL_ZONE_TYPES else 1.0

def risk_score(hard_brakes, occlusions, multiplier):
    return (WEIGHT_HARD_BRAKE * hard_brakes + WEIGHT_OCCLUSION * occlusions) * multiplier

def classify_risk(score, multiplier):
    if score >= CRITICAL_THRESHOLD:
        return "LEVEL_1_CRITICAL", f"Alta densidade de incidentes em perimetro de vulnerabilidade ({multiplier}x)."
    if score > 0:
        return "LEVEL_2_WARNING", "Incidentes dispersos registrados fora de zonas prioritarias."
    return None

def ticket_from_counts(crosswalk_id, city, hard_brakes, occlusions, multiplier):
    score = risk_score(int(hard_brakes or 0), int(occlusions or 0), float(multiplier or 1))
    ranked = classify_risk(score, float(multiplier or 1))
    if ranked is None:
        return None
    level, justification = ranked
    return {
        "crosswalk_id": crosswalk_id,
        "city": city,
        "metrics": {"hard_brakes": int(hard_brakes or 0), "occlusions": int(occlusions or 0)},
        "priority_level": level,
        "calculated_risk_score": round(score, 2),
        "zone_multiplier": float(multiplier or 1),
        "dispatch_justification": justification,
    }

def tickets_to_csv_rows(tickets):
    rows = [CSV_HEADER]
    for item in tickets:
        rows.append([item["crosswalk_id"], item["city"], item["metrics"]["hard_brakes"], item["metrics"]["occlusions"], item["zone_multiplier"], item["calculated_risk_score"], item["priority_level"]])
    return rows
