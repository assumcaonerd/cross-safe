"""Pure-python geospatial helpers used by tests and as a fallback."""

from __future__ import annotations

import math
from typing import Iterable

EARTH_RADIUS_M = 6371000.0


def haversine_m(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    rlat1, rlon1, rlat2, rlon2 = map(math.radians, (lat1, lon1, lat2, lon2))
    dlat = rlat2 - rlat1
    dlon = rlon2 - rlon1
    a = math.sin(dlat / 2) ** 2 + math.cos(rlat1) * math.cos(rlat2) * math.sin(dlon / 2) ** 2
    return 2 * EARTH_RADIUS_M * math.asin(math.sqrt(a))


def points_within_radius(
    origin_lat: float,
    origin_lon: float,
    points: Iterable[tuple[int, float, float]],
    radius_m: float,
) -> list[tuple[int, float]]:
    """Return (id, distance_m) for points inside the radius, nearest first."""
    hits: list[tuple[int, float]] = []
    for point_id, lat, lon in points:
        dist = haversine_m(origin_lat, origin_lon, lat, lon)
        if dist <= radius_m:
            hits.append((point_id, dist))
    hits.sort(key=lambda item: item[1])
    return hits


def braking_distance_m(speed_mps: float, reaction_s: float = 1.2, decel_mps2: float = 4.0) -> float:
    """Simple kinematic window: d = v*t + v^2 / (2a)."""
    speed = max(0.0, speed_mps)
    return speed * reaction_s + (speed * speed) / (2.0 * max(decel_mps2, 0.1))
