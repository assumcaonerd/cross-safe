import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/haptic_service.dart';
import '../models/role.dart';

/// Interface 1.3: Estado de Interrupcao Cognitiva.
/// Tela cheia, sem chrome, pensada para quebrar a distracao do motorista.
class DriverInterruptScreen extends StatefulWidget {
  const DriverInterruptScreen({
    super.key,
    this.distanceM = 50,
    this.speedKmh = 60,
    this.crosswalkName = 'Faixa a frente',
  });

  final double distanceM;
  final double speedKmh;
  final String crosswalkName;

  @override
  State<DriverInterruptScreen> createState() => _DriverInterruptScreenState();
}

class _DriverInterruptScreenState extends State<DriverInterruptScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  Timer? _audioCue;
  final _haptic = HapticService();

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..repeat(reverse: true);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _kickInterrupt();
    _audioCue = Timer.periodic(const Duration(milliseconds: 900), (_) {
      _haptic.alertFor(UserRole.driver, urgent: true);
      SystemSound.play(SystemSoundType.alert);
    });
  }

  Future<void> _kickInterrupt() async {
    await _haptic.alertFor(UserRole.driver, urgent: true);
    SystemSound.play(SystemSoundType.alert);
  }

  @override
  void dispose() {
    _audioCue?.cancel();
    _pulse.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF8B0000),
        body: SafeArea(
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              final glow = 0.55 + (_pulse.value * 0.45);
              return Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 1.1,
                    colors: [
                      Color.fromRGBO(255, 40, 40, glow),
                      const Color(0xFF4A0000),
                    ],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  children: [
                    _latencyBar(),
                    const SizedBox(height: 18),
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 72 + (_pulse.value * 10),
                      color: Colors.amber.shade200,
                    ),
                    const SizedBox(height: 4),
                    const Icon(Icons.directions_walk, size: 54, color: Colors.white),
                    const SizedBox(height: 18),
                    Text(
                      'FREIE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 42 + (_pulse.value * 4),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _panel(
                      'FAIXA EM ${widget.distanceM.round()} METROS',
                      widget.crosswalkName.toUpperCase(),
                    ),
                    const SizedBox(height: 12),
                    _panel(
                      'APROXIMACAO CINEMATICA',
                      '${widget.speedKmh.round()} km/h  ·  VETOR ATIVO',
                    ),
                    const Spacer(),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                            child: Text(
                              'HUD INJETADO',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          Text(
                            'AUDIO MONO INTERRUPT',
                            style: TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Alerta reconhecido',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _latencyBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: const Text(
        '[!] CRITICO  ·  LATENCIA: EDGE CORE  ·  REFRESH: 10 ms',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.amber,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _panel(String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        border: Border.all(color: Colors.white70, width: 1.4),
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
