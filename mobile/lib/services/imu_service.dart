import 'dart:math';

import 'package:sensors_plus/sensors_plus.dart';

enum EdgeMode { pedestrian, lev, motorcycle, automotive, unknown }

class EdgeClassification {
  EdgeClassification({
    required this.mode,
    required this.hardBrake,
    required this.approachM,
  });

  final EdgeMode mode;
  final bool hardBrake;
  final double approachM;
}

class ImuService {
  final List<AccelerometerEvent> _acc = [];
  double lastSpeed = 0;

  void ingestAccel(AccelerometerEvent event) {
    _acc.add(event);
    if (_acc.length > 100) {
      _acc.removeAt(0);
    }
  }

  EdgeClassification classify() {
    if (_acc.length < 8) {
      return EdgeClassification(
        mode: EdgeMode.unknown,
        hardBrake: false,
        approachM: 25,
      );
    }
    final mags = _acc.map((e) => sqrt(e.x * e.x + e.y * e.y + e.z * e.z)).toList();
    final mean = mags.reduce((a, b) => a + b) / mags.length;
    final variance =
        mags.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) / mags.length;
    final std = sqrt(variance);
    final minX = _acc.map((e) => e.x).reduce(min);
    final hardBrake = minX <= -3.5 && lastSpeed >= 3;

    EdgeMode mode = EdgeMode.unknown;
    if (lastSpeed < 1.8 && std < 1.6) {
      mode = EdgeMode.pedestrian;
    } else if (lastSpeed >= 1.6 && lastSpeed <= 12) {
      mode = EdgeMode.lev;
    } else if (lastSpeed >= 8) {
      mode = EdgeMode.automotive;
    }

    final approach = lastSpeed * 1.2 + pow(lastSpeed, 2) / 8 + 25;
    return EdgeClassification(
      mode: mode,
      hardBrake: hardBrake,
      approachM: approach.toDouble(),
    );
  }
}
