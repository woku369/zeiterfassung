import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/time_entry.dart';
import '../models/employer.dart';
import '../models/tracked_location.dart';
import '../database/database_helper.dart';

class SyncResult {
  final int pushed;
  final int pulled;
  final List<String> errors;
  final Map<String, dynamic>? serverSettings;
  SyncResult({
    required this.pushed,
    required this.pulled,
    this.errors = const [],
    this.serverSettings,
  });
}

class SyncService {
  static final SyncService instance = SyncService._();
  SyncService._();

  String _normalize(String url) =>
      url.endsWith('/') ? url.substring(0, url.length - 1) : url;

  Map<String, String> _headers(String? apiKey) => {
        'Content-Type': 'application/json',
        if (apiKey != null && apiKey.isNotEmpty) 'x-api-key': apiKey,
      };

  Future<SyncResult> sync({
    required String baseUrl,
    String? apiKey,
    Map<String, dynamic>? localSettings,
  }) async {
    final db = DatabaseHelper.instance;
    final url = _normalize(baseUrl);
    final headers = _headers(apiKey);
    final errors = <String>[];

    // Unsynced time entries + alle Employers/Locations inkl. soft-deleted
    final unsynced  = await db.getUnsyncedEntries();
    final employers = await db.getAllEmployersForSync();
    final locations = await db.getAllLocationsForSync();
    final lastSync  = await db.getSyncState('last_sync_at') ?? '1970-01-01T00:00:00.000Z';

    try {
      final body = jsonEncode({
        'last_sync': lastSync,
        'entries':   unsynced.map((e) => e.toJson()).toList(),
        'employers': employers.map((e) => e.toJson()).toList(),
        'locations': locations.map((l) => l.toJson()).toList(),
        if (localSettings != null && localSettings.isNotEmpty)
          'settings': localSettings,
      });

      final resp = await http.post(
        Uri.parse('$url/api/sync'),
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 30));

      if (resp.statusCode != 200) {
        errors.add('Sync fehlgeschlagen: HTTP ${resp.statusCode}');
        return SyncResult(pushed: 0, pulled: 0, errors: errors);
      }

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final serverTs = data['server_ts'] as String? ?? DateTime.now().toIso8601String();

      // Apply server data locally
      final serverEntries = (data['entries'] as List<dynamic>? ?? [])
          .map((e) => TimeEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      final serverEmployers = (data['employers'] as List<dynamic>? ?? [])
          .map((e) => Employer.fromJson(e as Map<String, dynamic>))
          .toList();
      final serverLocations = (data['locations'] as List<dynamic>? ?? [])
          .map((e) => TrackedLocation.fromMap(_normalizeLocationMap(e as Map<String, dynamic>)))
          .toList();

      if (serverEntries.isNotEmpty) {
        await db.insertOrUpdateEntries(serverEntries);
      }
      if (serverEmployers.isNotEmpty) {
        await db.upsertEmployersFromServer(serverEmployers);
      }
      if (serverLocations.isNotEmpty) {
        await db.upsertLocationsFromServer(serverLocations);
      }

      // Mark local entries as synced, save sync timestamp
      if (unsynced.isNotEmpty) {
        await db.markAsSynced(unsynced.map((e) => e.id).toList());
      }
      await db.setSyncState('last_sync_at', serverTs);

      // Server settings (LWW: server wins, propagate to other devices)
      final rawSettings = data['settings'] as Map<String, dynamic>?;

      return SyncResult(
        pushed: unsynced.length,
        pulled: serverEntries.length + serverEmployers.length + serverLocations.length,
        errors: errors,
        serverSettings: rawSettings,
      );
    } catch (e) {
      errors.add('Sync fehlgeschlagen: $e');
      return SyncResult(pushed: 0, pulled: 0, errors: errors);
    }
  }

  // Server uses radius_m (int), local model uses radius_meters (double)
  Map<String, dynamic> _normalizeLocationMap(Map<String, dynamic> m) {
    final result = Map<String, dynamic>.from(m);
    if (result.containsKey('radius_m') && !result.containsKey('radius_meters')) {
      result['radius_meters'] = (result['radius_m'] as num?)?.toDouble() ?? 200.0;
    }
    return result;
  }

  Future<bool> testConnection({required String baseUrl, String? apiKey}) async {
    final url = _normalize(baseUrl);
    try {
      final resp = await http
          .get(Uri.parse('$url/api/health'), headers: _headers(apiKey))
          .timeout(const Duration(seconds: 10));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── NAS-Backup ──────────────────────────────────────────────────────────────

  Future<bool> pushBackup({
    required String baseUrl,
    String? apiKey,
    required Map<String, dynamic> payload,
  }) async {
    final url = _normalize(baseUrl);
    try {
      final resp = await http.post(
        Uri.parse('$url/api/backup'),
        headers: _headers(apiKey),
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 60));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> pullBackup({
    required String baseUrl,
    String? apiKey,
  }) async {
    final url = _normalize(baseUrl);
    try {
      final resp = await http
          .get(Uri.parse('$url/api/backup'), headers: _headers(apiKey))
          .timeout(const Duration(seconds: 60));
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
