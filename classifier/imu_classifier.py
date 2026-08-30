from __future__ import annotations

from dataclasses import dataclass
from enum import Enum
import math

SAMPLING_HZ = 50
WINDOW_SECONDS = 2
WINDOW_SIZE = SAMPLING_HZ * WINDOW_SECONDS
ACCEL_VARIANCE_LEV_MAX = 4.5
GYRO_VARIANCE_LEV_MIN = 0.15
VIBRATION_NOISE_THRESHOLD = 0.8

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

def _mag(x, y, z):
    return math.sqrt(x * x + y * y + z * z)

def _mean(values):
    return sum(values) / len(values) if values else 0.0

def _var(values):
    if len(values) < 2:
        return 0.0
    mu = _mean(values)
    return sum((v - mu) ** 2 for v in values) / len(values)

def extract_features(window):
    if len(window) < 4:
        raise ValueError("need at least 4 IMU samples")
    slice_ = window[-WINDOW_SIZE:]
    acc = [_mag(s.ax, s.ay, s.az) for s in slice_]
    gyr = [_mag(s.gx, s.gy, s.gz) for s in slice_]
    times = [s.t_s for s in slice_]
    speeds = [s.speed_mps for s in slice_ if s.speed_mps is not None]
    diffs = [abs(acc[i] - acc[i - 1]) for i in range(1, len(acc))]
    return {
        "acc_var": _var(acc),
        "gyro_var": _var(gyr),
        "vibration": _mean(diffs),
        "speed_mean": _mean(speeds) if speeds else 0.0,
        "min_long_accel": min(s.ax for s in slice_),
        "samples": len(slice_),
        "duration_s": max(times[-1] - times[0], 1e-6),
    }

def classify(window):
    feats = extract_features(window)
    if feats["samples"] < WINDOW_SIZE:
        return Classification(TransportMode.UNKNOWN, 0.2, False, 25.0, feats)
    speed = feats["speed_mean"]
    acc_var = feats["acc_var"]
    gyro_var = feats["gyro_var"]
    vibration = feats["vibration"]
    hard_brake = feats["min_long_accel"] <= -3.5 and speed >= 3.0
    if vibration > VIBRATION_NOISE_THRESHOLD and gyro_var > GYRO_VARIANCE_LEV_MIN:
        mode, confidence = (TransportMode.LEV, 0.82) if acc_var < ACCEL_VARIANCE_LEV_MAX else (TransportMode.MOTORCYCLE, 0.74)
    elif acc_var >= ACCEL_VARIANCE_LEV_MAX and gyro_var < GYRO_VARIANCE_LEV_MIN:
        mode, confidence = TransportMode.AUTOMOTIVE, 0.80
    elif speed < 1.8 and vibration < 0.45:
        mode, confidence = TransportMode.PEDESTRIAN, 0.78
    else:
        mode, confidence = TransportMode.PEDESTRIAN, 0.55
    approach = max(0.0, speed * 1.2 + (speed * speed) / 8.0 + 25.0)
    if hard_brake:
        confidence = min(0.95, confidence + 0.08)
    return Classification(mode, round(confidence, 3), hard_brake, round(approach, 1), feats)

class CrossSafeIMUClassifier:
    def __init__(self, sampling_rate_hz=SAMPLING_HZ):
        self.sampling_rate = sampling_rate_hz
        self.window_size = sampling_rate_hz * WINDOW_SECONDS
    def classify_transport_mode(self, samples):
        return classify(samples).mode.value
