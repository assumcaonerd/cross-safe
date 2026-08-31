import '../config/api_config.dart';
import 'offline_sync_service.dart';

class TelemetryEvent {
  TelemetryEvent({
    required this.transportMode,
    required this.eventType,
    required this.lat,
    required this.lon,
    this.speedMps,
    this.decelerationMps2,
    this.crosswalkId,
    this.distanceM,
    this.respectScore,
    this.screenActive,
    this.modeConfidence,
    this.source = 'in_app',
    this.city = 'Vitoria',
    this.features = const {},
  });

  final String transportMode;
  final String eventType;
  final double lat;
  final double lon;
  final double? speedMps;
  final double? decelerationMps2;
  final int? crosswalkId;
  final double? distanceM;
  final int? respectScore;
  final bool? screenActive;
  final double? modeConfidence;
  final String source;
  final String city;
  final Map<String, dynamic> features;

  Map<String, dynamic> toJson() => {
        'transport_mode': transportMode,
        'event_type': eventType,
        'lat': lat,
        'lon': lon,
        'speed_mps': speedMps,
        'deceleration_mps2': decelerationMps2,
        'crosswalk_id': crosswalkId,
        'distance_m': distanceM,
        'respect_score': respectScore,
        'screen_active': screenActive,
        'mode_confidence': modeConfidence,
        'source': source,
        'city': city,
        'features': features,
      };
}

class TelemetryService {
  TelemetryService({String? baseUrl, OfflineSyncService? outbox})
      : baseUrl = baseUrl ?? ApiConfig.baseUrl,
        outbox = outbox ??
            OfflineSyncService(baseUrl: baseUrl ?? ApiConfig.baseUrl);

  final String baseUrl;
  final OfflineSyncService outbox;

  Future<void> postEvent(TelemetryEvent event) async {
    await outbox.enqueueTelemetry(event.toJson());
  }

  Future<void> dispose() => outbox.dispose();
}
