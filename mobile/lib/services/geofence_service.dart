import 'dart:convert';
import 'dart:math';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

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
  GeofenceService({String? apiBase, http.Client? client})
      : apiBase = apiBase ?? ApiConfig.baseUrl,
        _client = client ?? http.Client();

  final String apiBase;
  final http.Client _client;

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

    try {
      final response = await _client.get(uri).timeout(const Duration(seconds: 4));
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
    } catch (_) {
      return [];
    }
  }

  double brakingWindow(double speedMps) {
    final speed = max(0.0, speedMps);
    return speed * 1.2 + pow(speed, 2) / 8 + 25;
  }

  void dispose() {
    _client.close();
  }
}
