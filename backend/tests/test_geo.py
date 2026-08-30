from app.geo import braking_distance_m, haversine_m, points_within_radius


def test_haversine_same_point():
    assert haversine_m(-20.2976, -40.2958, -20.2976, -40.2958) < 1e-6


def test_nearby_radius_vitoria():
    origin = (-20.2976, -40.2958)
    points = [
        (1, -20.2976, -40.2958),
        (2, -20.3150, -40.3120),
        (3, -19.9000, -43.9000),
    ]
    hits = points_within_radius(*origin, points, radius_m=4000)
    ids = [item[0] for item in hits]
    assert 1 in ids
    assert 3 not in ids


def test_braking_grows_with_speed():
    slow = braking_distance_m(5)
    fast = braking_distance_m(20)
    assert fast > slow * 3
