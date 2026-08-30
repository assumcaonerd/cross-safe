import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

enum EdgeMode { pedestrian, lev, motorcycle, automotive, unknown }

class EdgeClassification {
  EdgeClassification({required this.mode, required this.hardBrake, required this.approachM});
  final EdgeMode mode;
  final bool hardBrake;
  final double approachM;
}

class ImuService {
  static const accelVarLevMax = 4.5;
  static const gyroVarLevMin = 0.15;
  static const vibrationNoise = 0.8;
  final List<AccelerometerEvent> _acc = [];
  final List<GyroscopeEvent> _gyro = [];
  double lastSpeed = 0;

  void ingestAccel(AccelerometerEvent event) {
    _acc.add(event);
    if (_acc.length > 100) _acc.removeAt(0);
  }

  void ingestGyro(GyroscopeEvent event) {
    _gyro.add(event);
    if (_gyro.length > 100) _gyro.removeAt(0);
  }

  EdgeClassification classify() {
    if (_acc.length < 50) {
      return EdgeClassification(mode: EdgeMode.unknown, hardBrake: false, approachM: 25);
    }
    final accMags = _acc.map((e) => sqrt(e.x * e.x + e.y * e.y + e.z * e.z)).toList();
    final accVar = _variance(accMags);
    var gyroVar = 0.0;
    if (_gyro.length >= 8) {
      final gMags = _gyro.map((e) => sqrt(e.x * e.x + e.y * e.y + e.z * e.z)).toList();
      gyroVar = _variance(gMags);
    }
    var vibration = 0.0;
    for (var i = 1; i < accMags.length; i++) {
      vibration += (accMags[i] - accMags[i - 1]).abs();
    }
    vibration /= max(1, accMags.length - 1);
    final minX = _acc.map((e) => e.x).reduce(min);
    final hardBrake = minX <= -3.5 && lastSpeed >= 3;
    var mode = EdgeMode.pedestrian;
    if (vibration > vibrationNoise && gyroVar > gyroVarLevMin) {
      mode = accVar < accelVarLevMax ? EdgeMode.lev : EdgeMode.motorcycle;
    } else if (accVar >= accelVarLevMax && gyroVar < gyroVarLevMin) {
      mode = EdgeMode.automotive;
    }
    final approach = lastSpeed * 1.2 + pow(lastSpeed, 2) / 8 + 25;
    return EdgeClassification(mode: mode, hardBrake: hardBrake, approachM: approach.toDouble());
  }

  double _variance(List<double> values) {
    if (values.length < 2) return 0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    return values.map((v) => pow(v - mean, 2).toDouble()).reduce((a, b) => a + b) / values.length;
  }
}
