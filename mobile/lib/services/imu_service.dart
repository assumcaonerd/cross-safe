import 'dart:async';
import 'dart:math';

import 'package:sensors_plus/sensors_plus.dart';

enum EdgeMode { pedestrian, lev, motorcycle, automotive, unknown }

class EdgeClassification {
  EdgeClassification({
    required this.mode,
    required this.confidence,
    required this.hardBrake,
    required this.approachM,
    required this.features,
  });

  final EdgeMode mode;
  final double confidence;
  final bool hardBrake;
  final double approachM;
  final Map<String, double> features;
}

class ImuService {
  static const samplingHz = 50;
  static const windowSize = samplingHz * 2;
  static const accelVarLevMax = 4.5;
  static const gyroVarLevMin = 0.15;
  static const vibrationNoise = 0.8;

  final List<AccelerometerEvent> _acc = [];
  final List<GyroscopeEvent> _gyro = [];
  StreamSubscription<AccelerometerEvent>? _accSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  bool _started = false;

  double lastSpeed = 0;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    const interval = Duration(milliseconds: 20);
    _accSub = accelerometerEventStream(samplingPeriod: interval).listen(
      ingestAccel,
      onError: (_) {},
      cancelOnError: false,
    );
    _gyroSub = gyroscopeEventStream(samplingPeriod: interval).listen(
      ingestGyro,
      onError: (_) {},
      cancelOnError: false,
    );
  }

  void ingestAccel(AccelerometerEvent event) {
    _acc.add(event);
    if (_acc.length > windowSize) _acc.removeAt(0);
  }

  void ingestGyro(GyroscopeEvent event) {
    _gyro.add(event);
    if (_gyro.length > windowSize) _gyro.removeAt(0);
  }

  EdgeClassification classify() {
    final speed = max(0.0, lastSpeed).toDouble();
    final approach = (speed * 1.2 + pow(speed, 2) / 8 + 25).toDouble();
    if (_acc.length < windowSize) {
      return EdgeClassification(
        mode: EdgeMode.unknown,
        confidence: 0.2,
        hardBrake: false,
        approachM: approach,
        features: {
          'samples': _acc.length.toDouble(),
          'speed_mps': speed,
        },
      );
    }

    final accMags = _acc
        .map((e) => sqrt(e.x * e.x + e.y * e.y + e.z * e.z))
        .toList();
    final accVar = _variance(accMags);

    var gyroVar = 0.0;
    if (_gyro.length >= 8) {
      final gMags = _gyro
          .map((e) => sqrt(e.x * e.x + e.y * e.y + e.z * e.z))
          .toList();
      gyroVar = _variance(gMags);
    }

    var vibration = 0.0;
    for (var i = 1; i < accMags.length; i++) {
      vibration += (accMags[i] - accMags[i - 1]).abs();
    }
    vibration /= max(1, accMags.length - 1);

    final minX = _acc.map((e) => e.x).reduce(min);
    final hardBrake = minX <= -3.5 && speed >= 3;

    var mode = EdgeMode.pedestrian;
    var confidence = 0.55;
    if (vibration > vibrationNoise && gyroVar > gyroVarLevMin) {
      if (accVar < accelVarLevMax) {
        mode = EdgeMode.lev;
        confidence = 0.82;
      } else {
        mode = EdgeMode.motorcycle;
        confidence = 0.74;
      }
    } else if (accVar >= accelVarLevMax && gyroVar < gyroVarLevMin) {
      mode = EdgeMode.automotive;
      confidence = 0.80;
    } else if (speed < 1.8 && vibration < 0.45) {
      mode = EdgeMode.pedestrian;
      confidence = 0.78;
    }

    if (hardBrake) confidence = min(0.95, confidence + 0.08).toDouble();

    return EdgeClassification(
      mode: mode,
      confidence: confidence,
      hardBrake: hardBrake,
      approachM: approach,
      features: {
        'acc_var': accVar,
        'gyro_var': gyroVar,
        'vibration': vibration,
        'speed_mps': speed,
        'samples': _acc.length.toDouble(),
        'min_long_accel': minX,
      },
    );
  }

  double _variance(List<double> values) {
    if (values.length < 2) return 0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    return values
            .map((v) => pow(v - mean, 2).toDouble())
            .reduce((a, b) => a + b) /
        values.length;
  }

  Future<void> stop() async {
    await _accSub?.cancel();
    await _gyroSub?.cancel();
    _accSub = null;
    _gyroSub = null;
    _started = false;
  }
}
