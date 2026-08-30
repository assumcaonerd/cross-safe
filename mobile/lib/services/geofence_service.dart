import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class NearbyCrosswalk {
  NearbyCrosswalk({
    required this.id,
    required this.name,
    required this.distanceM,
    required this.riskScore,
  });

  final int id;
  final String name;
  final double distanceM;
  final double riskScore;
}

class GeofenceService {
  GeofenceService({this.apiBase = 'http://10.0.2.2:8000'});

  final String apiBase;
  StreamSubscription<Position>? _sub;

  Future<bool> ensurePermission() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return false;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Stream<Position> watch() {
    const settings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 8,
    );
    return Geolocator.getPositionStream(locationSettings: settings);
  }

  Future<List<NearbyCrosswalk>> nearby({
    required double lat,
    required double lon,
    required double speedMps,
  }) async {
    final uri = Uri.parse(
      '$apiBase/v1/crosswalks/nearby?lat=$lat&lon=$lon&speed_mps=$speedMps',
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 4));
    if (response.statusCode != 200) return [];
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map(
          (item) => NearbyCrosswalk(
            id: item['id'] as int,
            name: item['name'] as String,
            distanceM: (item['distance_m'] as num?)?.toDouble() ?? 0,
            riskScore: (item['risk_score'] as num?)?.toDouble() ?? 0,
          ),
        )
        .toList();
  }

  double brakingWindow(double speedMps) {
    return speedMps * 1.2 + pow(speedMps, 2) / 8 + 25;
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }
}
