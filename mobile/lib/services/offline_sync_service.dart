import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../config/api_config.dart';

class OfflineSyncService {
  OfflineSyncService({String? baseUrl, this.batchSize = 25, http.Client? client})
      : baseUrl = baseUrl ?? ApiConfig.baseUrl,
        _client = client ?? http.Client();

  final String baseUrl;
  final int batchSize;
  final http.Client _client;
  bool _syncing = false;
  Database? _database;

  Future<Database> _db() async {
    if (_database != null) return _database!;
    final root = await getDatabasesPath();
    final path = p.join(root, 'crosssafe_outbox.db');
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute(
          '''
          CREATE TABLE pending_telemetry (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            payload TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            attempts INTEGER NOT NULL DEFAULT 0,
            last_error TEXT
          )
          ''',
        );
        await db.execute(
          'CREATE INDEX idx_pending_telemetry_created_at '
          'ON pending_telemetry(created_at)',
        );
        await db.execute(
          '''
          CREATE TABLE dead_letter_telemetry (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            payload TEXT NOT NULL,
            rejected_at INTEGER NOT NULL,
            status_code INTEGER,
            error TEXT
          )
          ''',
        );
      },
    );
    return _database!;
  }

  Future<int> get pendingCount async {
    final db = await _db();
    final result = await db.rawQuery('SELECT COUNT(*) AS total FROM pending_telemetry');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> enqueueTelemetry(Map<String, dynamic> telemetryPayload) async {
    final db = await _db();
    await db.insert('pending_telemetry', {
      'payload': jsonEncode(telemetryPayload),
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'attempts': 0,
    });
    unawaited(triggerSyncFlush());
  }

  Future<void> triggerSyncFlush() async {
    if (_syncing) return;
    _syncing = true;
    try {
      final health = await _client
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 3));
      if (health.statusCode != 200) return;

      final db = await _db();
      while (true) {
        final batch = await db.query(
          'pending_telemetry',
          orderBy: 'id ASC',
          limit: batchSize,
        );
        if (batch.isEmpty) return;

        var shouldContinue = true;
        for (final record in batch) {
          final id = record['id'] as int;
          final rawPayload = record['payload'] as String;
          final payload = jsonDecode(rawPayload) as Map<String, dynamic>;

          try {
            final response = await _client
                .post(
                  Uri.parse('$baseUrl/v1/telemetry'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode(payload),
                )
                .timeout(const Duration(seconds: 5));

            if (response.statusCode == 201) {
              await db.delete('pending_telemetry', where: 'id = ?', whereArgs: [id]);
              continue;
            }

            if (_isPermanentRejection(response.statusCode)) {
              await db.transaction((txn) async {
                await txn.insert('dead_letter_telemetry', {
                  'payload': rawPayload,
                  'rejected_at': DateTime.now().millisecondsSinceEpoch,
                  'status_code': response.statusCode,
                  'error': _truncate(response.body),
                });
                await txn.delete('pending_telemetry', where: 'id = ?', whereArgs: [id]);
              });
              continue;
            }

            await _markAttempt(db, id, 'HTTP ${response.statusCode}');
            shouldContinue = false;
            break;
          } catch (error) {
            await _markAttempt(db, id, error.runtimeType.toString());
            shouldContinue = false;
            break;
          }
        }

        if (!shouldContinue || batch.length < batchSize) return;
      }
    } catch (_) {
      return;
    } finally {
      _syncing = false;
    }
  }

  bool _isPermanentRejection(int statusCode) {
    return const {400, 404, 409, 422}.contains(statusCode);
  }

  Future<void> _markAttempt(Database db, int id, String error) async {
    await db.rawUpdate(
      'UPDATE pending_telemetry '
      'SET attempts = attempts + 1, last_error = ? WHERE id = ?',
      [error, id],
    );
  }

  String _truncate(String value) {
    if (value.length <= 1000) return value;
    return value.substring(0, 1000);
  }

  Future<void> dispose() async {
    _client.close();
    await _database?.close();
    _database = null;
  }
}
