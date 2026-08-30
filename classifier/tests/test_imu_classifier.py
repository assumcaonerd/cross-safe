import math
from classifier.imu_classifier import ImuSample, TransportMode, classify

def _pedestrian():
    return [ImuSample(i/50, 0.05, 0.02, 9.8 + 0.25*math.sin(2*math.pi*0.9*i/50), 0.02, 0.01, 0.01, 1.1) for i in range(100)]

def _lev():
    out = []
    for i in range(100):
        t = i/50
        road = 1.3 if i % 2 == 0 else -1.3
        steer = 2.4 * math.sin(2*math.pi*3.2*t)
        out.append(ImuSample(t, 0.3, road*0.15, 9.8+road, steer, 2.0*math.cos(2*math.pi*2.4*t), 1.4, 6.5))
    return out

def _car():
    return [ImuSample(i/50, 8.5*math.sin(2*math.pi*0.4*i/50), 0.2, 9.8+3.2*math.sin(2*math.pi*0.4*i/50), 0.03, 0.02, 0.01, 16.0) for i in range(100)]

def _moto():
    out = []
    for i in range(100):
        t = i/50
        road = 2.0 if i % 2 == 0 else -2.0
        surge = 8.0*math.sin(2*math.pi*0.55*t)
        steer = 2.2*math.sin(2*math.pi*2.8*t)
        out.append(ImuSample(t, surge, road, 9.8+road+2.5*math.sin(2*math.pi*0.55*t), 1.4, steer, 1.8*math.cos(2*math.pi*2.1*t), 12.0))
    return out

def test_pedestrian_low_speed():
    r = classify(_pedestrian())
    assert r.mode == TransportMode.PEDESTRIAN
    assert r.hard_brake is False

def test_lev_vibration_and_steering():
    r = classify(_lev())
    assert r.mode == TransportMode.LEV
    assert r.approach_vector_m > 25

def test_automotive_damped_gyro():
    assert classify(_car()).mode == TransportMode.AUTOMOTIVE

def test_motorcycle_noise_and_surge():
    assert classify(_moto()).mode == TransportMode.MOTORCYCLE

def test_hard_brake_flag():
    window = [ImuSample(s.t_s, -5.0, s.ay, s.az, s.gx, s.gy, s.gz, 12.0) for s in _car()]
    assert classify(window).hard_brake is True
