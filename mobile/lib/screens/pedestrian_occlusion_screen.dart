import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PedestrianOcclusionScreen extends StatefulWidget {
  const PedestrianOcclusionScreen({
    super.key,
    this.distanceM = 25,
    this.crosswalkName = 'Faixa a frente',
    this.screenActive = true,
  });

  final double distanceM;
  final String crosswalkName;
  final bool screenActive;

  @override
  State<PedestrianOcclusionScreen> createState() =>
      _PedestrianOcclusionScreenState();
}

class _PedestrianOcclusionScreenState extends State<PedestrianOcclusionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  Timer? _buzz;
  int _holdMs = 0;
  Timer? _holdTimer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..repeat(reverse: true);
    HapticFeedback.heavyImpact();
    _buzz = Timer.periodic(const Duration(milliseconds: 1100), (_) {
      HapticFeedback.mediumImpact();
      SystemSound.play(SystemSoundType.alert);
    });
  }

  @override
  void dispose() {
    _buzz?.cancel();
    _holdTimer?.cancel();
    _pulse.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _startHold() {
    _holdMs = 0;
    _holdTimer?.cancel();
    _holdTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      setState(() => _holdMs += 50);
      if (_holdMs >= 900 && mounted) {
        _holdTimer?.cancel();
        Navigator.of(context).pop();
      }
    });
  }

  void _cancelHold() {
    _holdTimer?.cancel();
    setState(() => _holdMs = 0);
  }

  @override
  Widget build(BuildContext context) {
    const yellow = Color(0xFFFFD60A);
    const ink = Color(0xFF111111);
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: yellow,
        body: AnimatedBuilder(
          animation: _pulse,
          builder: (context, _) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      color: ink,
                      child: const Text(
                        '[!] PEDESTRE DISTRAIDO   ·   OCLUSAO PERCEPTUAL',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: yellow, fontSize: 11, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.visibility, size: 36 + (_pulse.value * 6), color: ink),
                    const SizedBox(height: 8),
                    const Icon(Icons.directions_walk, size: 92, color: ink),
                    const SizedBox(height: 18),
                    Text(
                      'OLHE PARA CIMA',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: ink,
                        fontSize: 36 + (_pulse.value * 3),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'FAIXA A FRENTE',
                      style: TextStyle(color: ink, fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 28),
                    _chip('GEOFENCE: ${widget.distanceM.round()} m', widget.crosswalkName.toUpperCase()),
                    const SizedBox(height: 10),
                    _chip(
                      widget.screenActive ? 'TELA ATIVA DETECTADA' : 'CAMINHANDO SEM INTERACAO',
                      'SOBREPOSICAO FORCADA',
                    ),
                    const Spacer(),
                    LinearProgressIndicator(
                      value: (_holdMs / 900).clamp(0, 1),
                      minHeight: 8,
                      color: ink,
                      backgroundColor: ink.withValues(alpha: 0.15),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTapDown: (_) => _startHold(),
                      onTapUp: (_) => _cancelHold(),
                      onTapCancel: _cancelHold,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        color: ink,
                        child: const Text(
                          'SEGURE PARA CONFIRMAR QUE OLHOU',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: yellow, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _chip(String title, String subtitle) {
    const ink = Color(0xFF111111);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(border: Border.all(color: ink, width: 2)),
      child: Column(
        children: [
          Text(title, textAlign: TextAlign.center, style: const TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 2),
          Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: ink, fontSize: 12)),
        ],
      ),
    );
  }
}
