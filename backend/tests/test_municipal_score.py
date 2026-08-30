from app.municipal_score import classify_risk, risk_score, zone_multiplier

def test_school_zone_doubles_score():
    assert zone_multiplier("school") == 2.0
    assert zone_multiplier("hospital") == 2.0
    assert zone_multiplier("highway") == 1.0

def test_three_hard_brakes_at_school_is_critical():
    score = risk_score(3, 0, 2.0)
    assert score == 9.0
    level, _ = classify_risk(score, 2.0)
    assert level == "LEVEL_1_CRITICAL"

def test_one_occlusion_on_highway_is_warning():
    score = risk_score(0, 1, 1.0)
    level, _ = classify_risk(score, 1.0)
    assert level == "LEVEL_2_WARNING"

def test_zero_events_are_ignored():
    assert classify_risk(0, 1.0) is None
