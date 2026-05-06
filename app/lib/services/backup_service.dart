import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import 'sync_service.dart';

class BackupService {
  BackupService._();
  static final BackupService instance = BackupService._();

  static const _version = 1;
  static const _tables = ['employers', 'time_entries', 'tracked_locations', 'imap_config'];
  static const _prefKeys = [
    'activity_whitelist',
    'activity_min_duration_minutes',
    'activity_idle_threshold_minutes',
  ];

  /// Export all data to a JSON file chosen by the user.
  /// Returns the saved file path, or null if cancelled.
  Future<String?> export() async {
    final payload = await _buildPayload();
    final ts = DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());
    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Backup speichern',
      fileName: 'zeiterfassung_backup_$ts.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (savePath == null) return null;

    await File(savePath).writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
    );
    return savePath;
  }

  // ── NAS-Backup ──────────────────────────────────────────────────────────────

  /// Erstellt ein Backup und schickt es zum NAS.
  Future<bool> exportToNas({required String nasUrl, String? apiKey}) async {
    final payload = await _buildPayload();
    return SyncService.instance.pushBackup(
      baseUrl: nasUrl,
      apiKey: apiKey,
      payload: payload,
    );
  }

  /// Holt das letzte Backup vom NAS und importiert es lokal.
  Future<bool> importFromNas({required String nasUrl, String? apiKey}) async {
    final data = await SyncService.instance.pullBackup(
      baseUrl: nasUrl,
      apiKey: apiKey,
    );
    if (data == null) return false;
    await _applyPayload(data);
    return true;
  }

  Future<Map<String, dynamic>> _buildPayload() async {
    final db = await DatabaseHelper.instance.database;
    final prefs = await SharedPreferences.getInstance();

    final payload = <String, dynamic>{
      'version': _version,
      'exported_at': DateTime.now().toIso8601String(),
    };
    for (final table in _tables) {
      payload[table] = await db.query(table);
    }
    final settings = <String, dynamic>{};
    for (final key in _prefKeys) {
      final v = prefs.get(key);
      if (v != null) settings[key] = v;
    }
    payload['settings'] = settings;
    return payload;
  }

  Future<void> _applyPayload(Map<String, dynamic> data) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      for (final table in _tables.reversed) {
        await txn.delete(table);
      }
      for (final table in _tables) {
        for (final row in (data[table] as List? ?? [])) {
          await txn.insert(table, Map<String, dynamic>.from(row as Map),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    });

    final prefs = await SharedPreferences.getInstance();
    final settings = data['settings'] as Map<String, dynamic>? ?? {};
    for (final entry in settings.entries) {
      final v = entry.value;
      if (v is String) await prefs.setString(entry.key, v);
      if (v is int) await prefs.setInt(entry.key, v);
      if (v is double) await prefs.setDouble(entry.key, v);
      if (v is bool) await prefs.setBool(entry.key, v);
      if (v is List) await prefs.setStringList(entry.key, List<String>.from(v));
    }
  }

  // ── Lokales Backup (Datei) ──────────────────────────────────────────────────

  /// Import all data from a JSON backup file.
  /// Returns true on success, false if cancelled.
  Future<bool> import() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Backup öffnen',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    final path = result?.files.single.path;
    if (path == null) return false;

    final Map<String, dynamic> data =
        jsonDecode(await File(path).readAsString());
    await _applyPayload(data);
    return true;
  }
}
