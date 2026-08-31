import os

import pytest
from fastapi.testclient import TestClient

from app.main import app

pytestmark = pytest.mark.skipif(
    os.getenv("CROSSSAFE_INTEGRATION") != "1",
    reason="requires PostGIS integration database",
)

client = TestClient(app)


def test_health_checks_postgis():
    response = client.get("/health")
    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "ok"
    assert body["database"] == "ok"
    assert body["postgis"]


def test_priority_route_is_registered_once():
    matches = [
        route
        for route in app.routes
        if getattr(route, "path", None) == "/v1/municipal/priority-tickets"
        and "GET" in getattr(route, "methods", set())
    ]
    assert len(matches) == 1


def test_crosswalk_to_telemetry_to_municipal_ticket_roundtrip():
    nearby = client.get(
        "/v1/crosswalks/nearby",
        params={"lat": -20.2825, "lon": -40.2856, "radius_m": 300},
    )
    assert nearby.status_code == 200
    crosswalks = nearby.json()
    assert crosswalks
    crosswalk = crosswalks[0]

    payload = {
        "transport_mode": "automotive",
        "event_type": "hard_brake",
        "lat": -20.2825,
        "lon": -40.2856,
        "speed_mps": 12.0,
        "deceleration_mps2": -5.0,
        "crosswalk_id": crosswalk["id"],
        "distance_m": 28.0,
        "mode_confidence": 0.84,
        "source": "in_app",
        "city": crosswalk["city"],
        "features": {"vibration": 0.9},
    }

    for _ in range(3):
        response = client.post("/v1/telemetry", json=payload)
        assert response.status_code == 201

    tickets = client.get(
        "/v1/municipal/priority-tickets",
        params={"city": crosswalk["city"]},
    )
    assert tickets.status_code == 200
    body = tickets.json()
    assert body["total_tickets"] >= 1
    ticket = next(
        item for item in body["tickets"] if item["crosswalk_id"] == crosswalk["id"]
    )
    assert ticket["metrics"]["hard_brakes"] >= 3
    assert ticket["priority_level"] == "LEVEL_1_CRITICAL"

    csv_response = client.get(
        "/v1/municipal/priority-tickets.csv",
        params={"city": crosswalk["city"]},
    )
    assert csv_response.status_code == 200
    assert "crosswalk_id,city,hard_brakes_count" in csv_response.text
