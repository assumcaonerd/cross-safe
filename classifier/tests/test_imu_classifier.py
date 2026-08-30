from classifier.imu_classifier import ImuSample, TransportMode, classify


def _window(speed: float, az_amp: float = 0.2, freq: float = 0.0, ax: float = 0.0) -> list[ImuSample]:
    samples = []
    hz = 50
    for i in range(hz * 2):
        t = i / hz
        az = 9.8 + az_amp * __import__("math").sin(2 * 3.1415 * freq * t)
        samples.append(
            ImuSample(
                t_s=t,
                ax=ax,
                ay=0.05,
                az=az,
                gx=0.02,
                gy=0.01,
                gz=0.01,
                speed_mps=speed,
            )
        )
    return samples


def test_pedestrian_low_speed():
    result = classify(_window(speed=1.1, az_amp=0.3, freq=0.4))
    assert result.mode == TransportMode.PEDESTRIAN
    assert result.hard_brake is False


def test_lev_cadence_and_mid_speed():
    result = classify(_window(speed=6.0, az_amp=1.8, freq=1.4))
    assert result.mode == TransportMode.LEV
    assert result.approach_vector_m > 25


def test_automotive_high_speed_smooth():
    result = classify(_window(speed=16.0, az_amp=0.15, freq=0.1))
    assert result.mode == TransportMode.AUTOMOTIVE


def test_hard_brake_flag():
    result = classify(_window(speed=12.0, az_amp=0.2, freq=0.1, ax=-5.0))
    assert result.hard_brake is True
