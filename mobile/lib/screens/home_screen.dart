import 'package:flutter/material.dart';

import '../models/role.dart';
import '../services/geofence_service.dart';
import '../services/haptic_service.dart';
import '../services/imu_service.dart';
import 'driver_interrupt_screen.dart';

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
      if (hits.isNotEmpty) {
        final nearest = hits.first;
        final window = _geo.brakingWindow(position.speed);
        final urgent = nearest.distanceM <= window;
        setState(() {
          _status =
              '${_role.label}: ${nearest.name} a ${nearest.distanceM.toStringAsFixed(0)} m';
        });
        if (urgent || classification.hardBrake) {
          await _haptic.alertFor(_role, urgent: true);
          if (_role == UserRole.driver && mounted) {
            await Navigator.of(context).push(
              PageRouteBuilder(
                opaque: true,
                pageBuilder: (_, __, ___) => DriverInterruptScreen(
                  distanceM: nearest.distanceM,
                  speedKmh: position.speed * 3.6,
                  crosswalkName: nearest.name,
                ),
              ),
            );
          }
        }
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
                  .map(
                    (role) => ChoiceChip(
                      label: Text(role.label),
                      selected: _role == role,
                      onSelected: (_) => setState(() => _role = role),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
            Text(_status),
            const Spacer(),
            FilledButton(
              onPressed: _arm,
              child: const Text('Ativar alerta de faixa'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const DriverInterruptScreen(),
                  ),
                );
              },
              child: const Text('Previa da tela 1.3 (motorista)'),
            ),
          ],
        ),
      ),
    );
  }
}
