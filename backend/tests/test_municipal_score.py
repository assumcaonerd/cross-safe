from app.municipal_score import classify_risk, risk_score, ticket_from_counts, tickets_to_csv_rows, zone_multiplier

def test_school_zone_doubles_score():
    assert zone_multiplier("school") == 2.0

def test_three_hard_brakes_at_school_is_critical():
    assert risk_score(3, 0, 2.0) == 9.0
    level, _ = classify_risk(9.0, 2.0)
    assert level == "LEVEL_1_CRITICAL"

def test_one_occlusion_on_highway_is_warning():
    level, _ = classify_risk(1.0, 1.0)
    assert level == "LEVEL_2_WARNING"

def test_zero_events_are_ignored():
    assert classify_risk(0, 1.0) is None

def test_csv_rows_put_critical_first():
    rows = tickets_to_csv_rows([ticket_from_counts(1, "Vitoria", 3, 0, 2.0), ticket_from_counts(2, "Vitoria", 0, 1, 1.0)])
    assert rows[1][6] == "LEVEL_1_CRITICAL"
    assert rows[2][6] == "LEVEL_2_WARNING"
