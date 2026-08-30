from app.schemas import TelemetryIn

def test_extended_payload_parses():
    payload = TelemetryIn(
        transport_mode="pedestrian",
        event_type="occlusion_interrupt",
        lat=-20.2825,
        lon=-40.2856,
        distance_m=28,
        screen_active=True,
        source="overlay",
        city="Vitoria",
        features={"vibration": 0.2},
    )
    assert payload.distance_m == 28
    assert payload.features["vibration"] == 0.2
    assert payload.source == "overlay"
