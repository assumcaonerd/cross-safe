WEIGHT_HARD_BRAKE = 1.5
WEIGHT_OCCLUSION = 1.0
CRITICAL_ZONE_TYPES = frozenset({"school", "hospital"})
CRITICAL_MULTIPLIER = 2.0
CRITICAL_THRESHOLD = 5.0

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
