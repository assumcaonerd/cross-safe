"""Lightweight edge classifier for transport mode and hard-brake events.

The first version is heuristic on purpose: it must run on-device with no
heavy model, using only IMU windows plus optional GPS speed.
"""

from __future__ import annotations

from dataclasses import dataclass
from enum import Enum
import math


class TransportMode(str, Enum):
    PEDESTRIAN = "pedestrian"
    LEV = "lev"
    MOTORCYCLE = "motorcycle"
    AUTOMOTIVE = "automotive"
    UNKNOWN = "unknown"


@dataclass(frozen=True)
class ImuSample:
    t_s: float
    ax: float
    ay: float
    az: float
    gx: float
    gy: float
    gz: float
    speed_mps: float | None = None


@dataclass(frozen=True)
class Classification:
    mode: TransportMode
    confidence: float
    hard_brake: bool
    approach_vector_m: float
    features: dict


def _mag(x: float, y: float, z: float) -> float:
    return math.sqrt(x * x + y * y + z * z)


def _mean(values: list[float]) -> float:
    return sum(values) / len(values) if values else 0.0


def _std(values: list[float]) -> float:
    if len(values) < 2:
        return 0.0
    mu = _mean(values)
    var = sum((v - mu) ** 2 for v in values) / (len(values) - 1)
    return math.sqrt(var)


def _dominant_hz(times: list[float], series: list[float]) -> float:
    if len(series) < 6:
        return 0.0
    mu = _mean(series)
    crossings = 0
    for prev, curr in zip(series, series[1:]):
        if (prev - mu) == 0:
            continue
        if (prev - mu) * (curr - mu) < 0:
            crossings += 1
    duration = max(times[-1] - times[0], 1e-6)
    return (crossings / 2.0) / duration


def extract_features(window: list[ImuSample]) -> dict:
    if len(window) < 4:
        raise ValueError("need at least 4 IMU samples")

    acc = [_mag(s.ax, s.ay, s.az) for s in window]
    gyr = [_mag(s.gx, s.gy, s.gz) for s in window]
    times = [s.t_s for s in window]
    speeds = [s.speed_mps for s in window if s.speed_mps is not None]
    vertical = [s.az for s in window]

    dt = max(times[-1] - times[0], 1e-6)
    jerk = []
    for i in range(1, len(acc)):
        step = max(times[i] - times[i - 1], 1e-3)
        jerk.append((acc[i] - acc[i - 1]) / step)

    long_accel = [s.ax for s in window]
    min_long = min(long_accel)

    return {
        "acc_mean": _mean(acc),
        "acc_std": _std(acc),
        "gyro_mean": _mean(gyr),
        "speed_mean": _mean(speeds) if speeds else 0.0,
        "cadence_hz": _dominant_hz(times, vertical),
        "jerk_std": _std(jerk),
        "min_long_accel": min_long,
        "duration_s": dt,
    }


def classify(window: list[ImuSample]) -> Classification:
    feats = extract_features(window)
    speed = feats["speed_mean"]
    cadence = feats["cadence_hz"]
    acc_std = feats["acc_std"]
    gyro = feats["gyro_mean"]
    hard_brake = feats["min_long_accel"] <= -3.5 and speed >= 3.0

    mode = TransportMode.UNKNOWN
    confidence = 0.40

    if speed < 1.8 and acc_std < 1.6:
        mode = TransportMode.PEDESTRIAN
        confidence = 0.78
    elif 1.6 <= speed <= 12.0 and 0.7 <= cadence <= 2.6:
        mode = TransportMode.LEV
        confidence = 0.74
    elif speed >= 4.0 and gyro >= 0.8 and acc_std >= 2.2 and cadence < 0.7:
        mode = TransportMode.MOTORCYCLE
        confidence = 0.66
    elif speed >= 8.0 and cadence < 0.8:
        mode = TransportMode.AUTOMOTIVE
        confidence = 0.72
    elif speed >= 3.0:
        mode = TransportMode.LEV if cadence >= 0.6 else TransportMode.AUTOMOTIVE
        confidence = 0.52

    approach = max(0.0, speed * 1.2 + (speed * speed) / 8.0 + 25.0)

    if hard_brake:
        confidence = min(0.95, confidence + 0.08)

    return Classification(
        mode=mode,
        confidence=round(confidence, 3),
        hard_brake=hard_brake,
        approach_vector_m=round(approach, 1),
        features=feats,
    )
