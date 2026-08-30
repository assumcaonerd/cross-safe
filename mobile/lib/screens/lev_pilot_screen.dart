import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LevPilotScreen extends StatelessWidget {
  const LevPilotScreen({
    super.key,
    this.speedKmh = 24.5,
    this.distanceM = 60,
    this.respectScore = 98,
    this.crosswalkName = 'Eco-zone crosswalk',
    this.schoolZone = false,
    this.hardBrake = false,
  });

  final double speedKmh;
  final double distanceM;
  final int respectScore;
  final String crosswalkName;
  final bool schoolZone;
  final bool hardBrake;

  static const emerald = Color(0xFF00E676);
  static const alertOrange = Color(0xFFFF9100);
  static const bg = Color(0xFF121212);

  bool get _tooFast => schoolZone ? speedKmh > 25 : speedKmh > 28;
  Color get _accent => (_tooFast || hardBrake) ? alertOrange : emerald;

  int get _score {
    var score = respectScore;
    if (hardBrake) score -= 12;
    if (_tooFast) score -= 8;
    if (distanceM <= 60 && speedKmh > 15) score -= 4;
    return score.clamp(0, 100);
  }

  double get _recommendedKmh {
    if (distanceM <= 40) return 12;
    if (distanceM <= 80) return 15;
    return 20;
  }

  @override
  Widget build(BuildContext context) {
    if (hardBrake) HapticFeedback.heavyImpact();
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(color: Colors.black, border: Border.all(color: _accent.withValues(alpha: 0.6))),
                child: Text(
                  'LEV MODE  ·  SENSORES ONLINE  ·  CONFORMIDADE $_score%',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _accent, fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
              const Spacer(),
              const Text('RESPECT SCORE', style: TextStyle(color: Colors.white54, letterSpacing: 2, fontSize: 12, fontWeight: FontWeight.w700)),
              Text('$_score pt', style: TextStyle(color: _accent, fontSize: 56, fontWeight: FontWeight.w900)),
              const SizedBox(height: 18),
              const Text('VELOCIDADE ATUAL', style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1.4)),
              Text('${speedKmh.toStringAsFixed(1)} km/h', style: TextStyle(color: _accent, fontSize: 40, fontWeight: FontWeight.w800)),
              const SizedBox(height: 28),
              _block('A FRENTE: ${crosswalkName.toUpperCase()}', 'EM ${distanceM.round()} METROS'),
              const SizedBox(height: 12),
              _block('VETOR DE FRENAGEM RECOMENDADO', '< ${_recommendedKmh.round()} km/h'),
              if (schoolZone) ...[
                const SizedBox(height: 12),
                _block('ZONA DE ALTA DENSIDADE DE PEDESTRES', 'REDUZA'),
              ],
              const Spacer(),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(border: Border.all(color: _accent.withValues(alpha: 0.5))),
                child: Text(
                  hardBrake ? 'FRENAGEM BRUSCA · SCORE AJUSTADO' : 'GEOCONTEXTIVO ATIVO · PIPELINE DO ACELEROMETRO',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _accent, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Voltar ao painel', style: TextStyle(color: Colors.white38)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _block(String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(height: 4),
          Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: _accent, fontSize: 16, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
