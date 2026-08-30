import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DriverAwarenessScreen extends StatefulWidget {
  const DriverAwarenessScreen({
    super.key,
    this.distanceM = 150,
    this.speedKmh = 50,
    this.crosswalkName = 'Faixa a frente',
  });

  final double distanceM;
  final double speedKmh;
  final String crosswalkName;

  @override
  State<DriverAwarenessScreen> createState() => _DriverAwarenessScreenState();
}

class _DriverAwarenessScreenState extends State<DriverAwarenessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  Timer? _nudge;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
    HapticFeedback.lightImpact();
    _nudge = Timer.periodic(const Duration(seconds: 3), (_) {
      HapticFeedback.lightImpact();
      SystemSound.play(SystemSoundType.click);
    });
  }

  @override
  void dispose() {
    _nudge?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    const anthracite = Color(0xFF1C1C1E);
    const amber = Color(0xFFFFCC00);
    return GestureDetector(
      onVerticalDragEnd: (details) {
        if ((details.primaryVelocity ?? 0) > 380) _dismiss();
      },
      child: Scaffold(
        backgroundColor: anthracite,
        body: AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            final borderColor = Color.lerp(
              amber,
              amber.withValues(alpha: 0.22),
              _pulse.value,
            )!;
            return Container(
              decoration: BoxDecoration(
                color: anthracite,
                border: Border.all(color: borderColor, width: 10),
              ),
              child: child,
            );
          },
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      border: Border.all(color: amber.withValues(alpha: 0.5)),
                    ),
                    child: const Text(
                      '[!] CROSSWALK AWARENESS   ·   TELEMETRIA ATIVA   ·   100 ms',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: amber, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.wifi_tethering, color: amber.withValues(alpha: 0.7), size: 28),
                  const SizedBox(height: 10),
                  const Icon(Icons.directions_walk, size: 96, color: amber),
                  const SizedBox(height: 22),
                  const Text(
                    'APROXIMACAO DA FAIXA',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: 1.4),
                  ),
                  const SizedBox(height: 28),
                  _block('FAIXA DETECTADA EM ${widget.distanceM.round()} METROS', widget.crosswalkName.toUpperCase()),
                  const SizedBox(height: 12),
                  _block('VELOCIDADE ATUAL: ${widget.speedKmh.round()} km/h', 'JANELA SEGURA DE APROXIMACAO'),
                  const Spacer(),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Text(
                      'STATUS: MONITORANDO EM BACKGROUND   ·   VETOR DE NOTIFICACAO ATIVO',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ),
                  TextButton(
                    onPressed: _dismiss,
                    child: const Text('Minimizar  ·  arraste para baixo', style: TextStyle(color: Colors.white54)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _block(String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
          const SizedBox(height: 4),
          Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }
}
