import 'package:flutter_test/flutter_test.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'package:cross_safe/services/imu_service.dart';

void main() {
  test('classification stays unknown until the two-second window is full', () {
    final service = ImuService()..lastSpeed = 8;
    for (var i = 0; i < 50; i++) {
      final at = DateTime.fromMillisecondsSinceEpoch(i * 20);
      service.ingestAccel(AccelerometerEvent(0, 0, 9.8, at));
      service.ingestGyro(GyroscopeEvent(0, 0, 0, at));
    }

    final result = service.classify();
    expect(result.mode, EdgeMode.unknown);
    expect(result.features['samples'], 50);
  });

  test('full IMU window can flag a hard brake', () {
    final service = ImuService()..lastSpeed = 12;
    for (var i = 0; i < ImuService.windowSize; i++) {
      final at = DateTime.fromMillisecondsSinceEpoch(i * 20);
      service.ingestAccel(AccelerometerEvent(-5, 0, 9.8, at));
      service.ingestGyro(GyroscopeEvent(0, 0, 0, at));
    }

    final result = service.classify();
    expect(result.hardBrake, isTrue);
    expect(result.approachM, greaterThan(25));
    expect(result.features['samples'], ImuService.windowSize);
  });
}
