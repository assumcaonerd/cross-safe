import 'package:flutter/material.dart';

import '../models/role.dart';
import '../services/geofence_service.dart';
import '../services/haptic_service.dart';
import '../services/imu_service.dart';
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
  String _status = 'Aguardando permissao de localizacao';
  bool _awarenessOpen = false;
  bool _interruptOpen = false;
  bool _occlusionOpen = false;
  bool _levOpen = false;
  int _respectScore = 98;

  Future<void> _arm() async {
    final ok = await _geo.ensurePermission();
    if (!ok) {
      setState(() => _status = 'Localizacao negada');
      return;
    }
    setState(() => _status = 'Monitorando faixas proximas');
    await for (final position in _geo.watch()) {
      if (!mounted) return;
      _imu.lastSpeed = position.speed;
      final classification = _imu.classify();
      final hits = await _geo.nearby(
        lat: position.latitude,
        lon: position.longitude,
        speedMps: position.speed,
      );
      if (hits.isEmpty) continue;
      final nearest = hits.first;
      final window = _geo.brakingWindow(position.speed);
      final speedKmh = position.speed * 3.6;
      final urgent = nearest.distanceM <= window || classification.hardBrake;
      final early = !urgent && nearest.distanceM <= window + 120;
      setState(() {
        _status =
            '${_role.label}: ${nearest.name} a ${nearest.distanceM.toStringAsFixed(0)} m';
      });
      if (_role == UserRole.pedestrian) {
        if (nearest.distanceM <= 40 && !_occlusionOpen && mounted) {
          _occlusionOpen = true;
          await _haptic.alertFor(_role, urgent: true);
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
        continue;
      }
      if (_role == UserRole.rider) {
        if (classification.hardBrake) {
          _respectScore = (_respectScore - 12).clamp(0, 100);
        }
        final approaching = nearest.distanceM <= window + 80;
        if (approaching && !_levOpen && mounted) {
          _levOpen = true;
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
        continue;
      }
      if (urgent && !_interruptOpen && mounted) {
        _interruptOpen = true;
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
        continue;
      }
      if (early && !_awarenessOpen && !_interruptOpen && mounted) {
        _awarenessOpen = true;
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
    }
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
                  .map((role) => ChoiceChip(
                        label: Text(role.label),
                        selected: _role == role,
                        onSelected: (_) => setState(() => _role = role),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
            Text(_status),
            const Spacer(),
            FilledButton(onPressed: _arm, child: const Text('Ativar alerta de faixa')),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DriverAwarenessScreen())),
              child: const Text('Previa da tela 1.2 (aproximacao)'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DriverInterruptScreen())),
              child: const Text('Previa da tela 1.3 (critico)'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PedestrianOcclusionScreen())),
              child: const Text('Previa da tela 1.4 (pedestre)'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LevPilotScreen())),
              child: const Text('Previa do modo LEV (e-bike)'),
            ),
          ],
        ),
      ),
    );
  }
}
