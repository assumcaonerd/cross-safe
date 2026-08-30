import 'dart:convert';
import 'package:http/http.dart' as http;

class PendingRecord {
  PendingRecord({required this.id, required this.payload, required this.timestamp});
  final int id;
  final Map<String, dynamic> payload;
  final int timestamp;
}

class OfflineSyncService {
  OfflineSyncService({this.baseUrl = 'http://127.0.0.1:8000', this.batchSize = 25, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final int batchSize;
  final http.Client _client;
  final List<PendingRecord> _queue = [];
  int _seq = 0;
  bool _syncing = false;
  int get pendingCount => _queue.length;

  Future<void> enqueueTelemetry(Map<String, dynamic> telemetryPayload) async {
    _seq += 1;
    _queue.add(PendingRecord(id: _seq, payload: Map<String, dynamic>.from(telemetryPayload), timestamp: DateTime.now().millisecondsSinceEpoch));
    await triggerSyncFlush();
  }

  Future<void> triggerSyncFlush() async {
    if (_syncing) return;
    _syncing = true;
    try {
      final health = await _client.get(Uri.parse('$baseUrl/health')).timeout(const Duration(seconds: 3));
      if (health.statusCode != 200) return;
      final batch = _queue.take(batchSize).toList();
      if (batch.isEmpty) return;
      final accepted = <int>[];
      for (final record in batch) {
        final response = await _client.post(
          Uri.parse('$baseUrl/v1/telemetry'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(record.payload),
        );
        if (response.statusCode == 201 || response.statusCode == 400) {
          accepted.add(record.id);
        } else {
          break;
        }
      }
      _queue.removeWhere((item) => accepted.contains(item.id));
      if (accepted.length == batchSize && _queue.isNotEmpty) {
        _syncing = false;
        await triggerSyncFlush();
        return;
      }
    } catch (_) {
    } finally {
      _syncing = false;
    }
  }
}
