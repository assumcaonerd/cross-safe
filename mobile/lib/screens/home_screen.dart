import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/role.dart';
import '../services/geofence_service.dart';
import '../services/haptic_service.dart';
import '../services/imu_service.dart';
import '../services/telemetry_service.dart';
import 'driver_awareness_screen.dart';
import 'driver_interrupt_screen.dart';
import 'lev_pilot_screen.dart';
import 'pedestrian_occlusion_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserRole _role = UserRole.pedestrian;
  final _geo = GeofenceService();
  final _imu = ImuService();
  final _haptic = HapticService();
  final _telemetry = TelemetryService();

  StreamSubscription<Position>? _geoSubscription;
  String _status = 'Aguardando permissao de localizacao';
  bool _monitoring = false;
  bool _processingPosition = false;
  bool _awarenessOpen = false;
  bool _interruptOpen = false;
  bool _occlusionOpen = false;
  bool _levOpen = false;
  int _respectScore = 98;
  String? _lastAlertKey;
  DateTime? _lastAlertAt;

  Future<void> _arm() async {
    if (_monitoring) return;
    final ok = await _geo.ensurePermission();
    if (!ok) {
      if (mounted) setState(() => _status = 'Localizacao negada ou desativada');
      return;
    }

    await _imu.start();
    if (!mounted) return;
    setState(() {
      _monitoring = true;
      _status = 'Monitorando faixas proximas';
    });

    _geoSubscription = _geo.watch().listen(
      (position) => unawaited(_handlePosition(position)),
      onError: (Object error) {
        if (mounted) {
          setState(() => _status = 'Falha no GPS: ${error.runtimeType}');
        }
      },
    );
  }

  Future<void> _disarm() async {
    await _geoSubscription?.cancel();
    _geoSubscription = null;
    await _imu.stop();
    if (!mounted) return;
    setState(() {
      _monitoring = false;
      _status = 'Alertas desativados';
    });
  }

  Future<void> _handlePosition(Position position) async {
    if (!_monitoring || _processingPosition || !mounted) return;
    _processingPosition = true;
    try {
      final speedMps = position.speed < 0 ? 0.0 : position.speed;
      _imu.lastSpeed = speedMps;
      final classification = _imu.classify();
      final hits = await _geo.nearby(
        lat: position.latitude,
        lon: position.longitude,
        speedMps: speedMps,
      );
      if (!_monitoring || !mounted || hits.isEmpty) return;

      final nearest = hits.first;
      final window = _geo.brakingWindow(speedMps);
      final speedKmh = speedMps * 3.6;
      final urgent = nearest.distanceM <= window || classification.hardBrake;
      final early = !urgent && nearest.distanceM <= window + 120;

      setState(() {
        _status =
            '${_role.label}: ${nearest.name} a ${nearest.distanceM.toStringAsFixed(0)} m';
      });

      if (_role == UserRole.pedestrian) {
        final key = 'pedestrian:${nearest.id}';
        if (nearest.distanceM <= 40 &&
            !_occlusionOpen &&
            _cooldownAllows(key) &&
            mounted) {
          _occlusionOpen = true;
          await _haptic.alertFor(_role, urgent: true);
          if (!mounted) {
            _occlusionOpen = false;
            return;
          }
          _recordTelemetry(
            position: position,
            speedMps: speedMps,
            nearest: nearest,
            classification: classification,
            eventType: 'occlusion_interrupt',
            screenActive: true,
          );
          await Navigator.of(context).push(
            PageRouteBuilder(
              opaque: true,
              pageBuilder: (_, __, ___) => PedestrianOcclusionScreen(
                distanceM: nearest.distanceM,
                crosswalkName: nearest.name,
                screenActive: true,
              ),
            ),
          );
          _occlusionOpen = false;
        }
        return;
      }

      if (_role == UserRole.rider) {
        final approaching = nearest.distanceM <= window + 80;
        final key = 'rider:${nearest.id}';
        if (approaching && !_levOpen && _cooldownAllows(key) && mounted) {
          _levOpen = true;
          if (classification.hardBrake) {
            _respectScore = (_respectScore - 12).clamp(0, 100).toInt();
            await _haptic.alertFor(_role, urgent: true);
          }
          if (!mounted) {
            _levOpen = false;
            return;
          }
          _recordTelemetry(
            position: position,
            speedMps: speedMps,
            nearest: nearest,
            classification: classification,
            eventType: classification.hardBrake ? 'hard_brake' : 'lev_approach',
            respectScore: _respectScore,
          );
          await Navigator.of(context).push(
            PageRouteBuilder(
              opaque: false,
              pageBuilder: (_, __, ___) => LevPilotScreen(
                speedKmh: speedKmh,
                distanceM: nearest.distanceM,
                respectScore: _respectScore,
                crosswalkName: nearest.name,
                hardBrake: classification.hardBrake,
              ),
            ),
          );
          _levOpen = false;
        }
        return;
      }

      if (urgent && !_interruptOpen && mounted) {
        final key = 'driver-critical:${nearest.id}';
        if (!_cooldownAllows(key)) return;
        _interruptOpen = true;
        await _haptic.alertFor(_role, urgent: true);
        if (!mounted) {
          _interruptOpen = false;
          return;
        }
        _recordTelemetry(
          position: position,
          speedMps: speedMps,
          nearest: nearest,
          classification: classification,
          eventType: classification.hardBrake ? 'hard_brake' : 'driver_interrupt',
        );
        await Navigator.of(context).push(
          PageRouteBuilder(
            opaque: true,
            pageBuilder: (_, __, ___) => DriverInterruptScreen(
              distanceM: nearest.distanceM,
              speedKmh: speedKmh,
              crosswalkName: nearest.name,
            ),
          ),
        );
        _interruptOpen = false;
        return;
      }

      if (early && !_awarenessOpen && !_interruptOpen && mounted) {
        final key = 'driver-early:${nearest.id}';
        if (!_cooldownAllows(key)) return;
        _awarenessOpen = true;
        _recordTelemetry(
          position: position,
          speedMps: speedMps,
          nearest: nearest,
          classification: classification,
          eventType: 'driver_awareness',
        );
        await Navigator.of(context).push(
          PageRouteBuilder(
            opaque: false,
            pageBuilder: (_, __, ___) => DriverAwarenessScreen(
              distanceM: nearest.distanceM,
              speedKmh: speedKmh,
              crosswalkName: nearest.name,
            ),
          ),
        );
        _awarenessOpen = false;
      }
    } finally {
      _processingPosition = false;
    }
  }

  bool _cooldownAllows(String key) {
    final now = DateTime.now();
    if (_lastAlertKey == key &&
        _lastAlertAt != null &&
        now.difference(_lastAlertAt!) < const Duration(seconds: 20)) {
      return false;
    }
    _lastAlertKey = key;
    _lastAlertAt = now;
    return true;
  }

  void _recordTelemetry({
    required Position position,
    required double speedMps,
    required NearbyCrosswalk nearest,
    required EdgeClassification classification,
    required String eventType,
    int? respectScore,
    bool? screenActive,
  }) {
    unawaited(
      _telemetry.postEvent(
        TelemetryEvent(
          transportMode: classification.mode.name,
          eventType: eventType,
          lat: position.latitude,
          lon: position.longitude,
          speedMps: speedMps,
          decelerationMps2: classification.features['min_long_accel'],
          crosswalkId: nearest.id,
          distanceM: nearest.distanceM,
          respectScore: respectScore,
          screenActive: screenActive,
          modeConfidence: classification.confidence,
          city: nearest.city,
          features: classification.features,
        ),
      ),
    );
  }

  @override
  void dispose() {
    final subscription = _geoSubscription;
    if (subscription != null) unawaited(subscription.cancel());
    unawaited(_imu.stop());
    unawaited(_telemetry.dispose());
    _geo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CrossSafe')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quem esta usando o aparelho agora?'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: UserRole.values
                  .map(
                    (role) => ChoiceChip(
                      label: Text(role.label),
                      selected: _role == role,
                      onSelected: _monitoring
                          ? null
                          : (_) => setState(() => _role = role),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
            Text(_status),
            const Spacer(),
            FilledButton(
              onPressed: _monitoring ? _disarm : _arm,
              child: Text(
                _monitoring ? 'Desativar alertas' : 'Ativar alerta de faixa',
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DriverAwarenessScreen()),
              ),
              child: const Text('Previa da tela 1.2 (aproximacao)'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DriverInterruptScreen()),
              ),
              child: const Text('Previa da tela 1.3 (critico)'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PedestrianOcclusionScreen(),
                ),
              ),
              child: const Text('Previa da tela 1.4 (pedestre)'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LevPilotScreen()),
              ),
              child: const Text('Previa do modo LEV (e-bike)'),
            ),
          ],
        ),
      ),
    );
  }
}
