import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class OverlayService {
  OverlayService({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('com.crosssafe.app/overlay');

  final MethodChannel _channel;
  bool _running = false;
  bool get isRunning => _running;

  Future<bool> checkPermission() async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    return await _channel.invokeMethod<bool>('checkPermission') ?? false;
  }

  Future<void> requestPermission() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    await _channel.invokeMethod<bool>('requestPermission');
  }

  Future<bool> startOverlay({
    required double distanceM,
    required String crosswalkId,
    String crosswalkName = 'Faixa a frente',
  }) async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    if (!await checkPermission()) {
      await requestPermission();
      return false;
    }
    await _channel.invokeMethod<bool>('startOverlay', {
      'distance': distanceM,
      'crosswalkId': crosswalkId,
      'crosswalkName': crosswalkName,
    });
    _running = true;
    return true;
  }

  Future<void> stopOverlay() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    await _channel.invokeMethod<bool>('stopOverlay');
    _running = false;
  }
}
