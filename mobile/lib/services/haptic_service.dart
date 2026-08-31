import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

import '../models/role.dart';

class HapticService {
  Future<void> alertFor(UserRole role, {required bool urgent}) async {
    if (await Vibration.hasVibrator()) {
      if (urgent) {
        await Vibration.vibrate(pattern: [0, 80, 40, 80, 40, 160]);
      } else {
        await Vibration.vibrate(
          duration: role == UserRole.pedestrian ? 220 : 120,
        );
      }
    } else {
      await HapticFeedback.heavyImpact();
    }
  }
}
