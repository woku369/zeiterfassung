import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/activity_log.dart';
import '../database/database_helper.dart';
import '../services/activity_tracking_service.dart';

class ActivityProvider extends ChangeNotifier {
  static const _keyWhitelist = 'activity_whitelist';
  static const _keyMinDuration = 'activity_min_duration_minutes';
  static const _keyIdleThreshold = 'activity_idle_threshold_minutes';

  List<ActivityLog> _sessions = [];
  List<String> _whitelist = List.from(defaultWhitelist);
  int _minDurationMinutes = 3;
  int _idleThresholdMinutes = 5;
  bool _isTracking = false;
  bool _hasPermission = false;
  DateTime _selectedDate = DateTime.now();

  List<ActivityLog> get sessions => _sessions;
  List<String> get whitelist => _whitelist;
  int get minDurationMinutes => _minDurationMinutes;
  int get idleThresholdMinutes => _idleThresholdMinutes;
  bool get isTracking => _isTracking;
  bool get hasPermission => _hasPermission;
  DateTime get selectedDate => _selectedDate;

  bool get isSupported => Platform.isWindows || Platform.isAndroid;

  Future<void> init() async {
    await _loadSettings();
    if (Platform.isAndroid) {
      _hasPermission = await ActivityTrackingService.instance.hasAndroidUsagePermission();
    } else {
      _hasPermission = true;
    }
    notifyListeners();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_keyWhitelist);
    if (saved != null) _whitelist = saved;
    _minDurationMinutes = prefs.getInt(_keyMinDuration) ?? 3;
    _idleThresholdMinutes = prefs.getInt(_keyIdleThreshold) ?? 5;
  }

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyWhitelist, _whitelist);
    await prefs.setInt(_keyMinDuration, _minDurationMinutes);
    await prefs.setInt(_keyIdleThreshold, _idleThresholdMinutes);
    notifyListeners();
  }

  void setWhitelist(List<String> list) {
    _whitelist = list;
  }

  /// Vom NAS empfangene Settings übernehmen (LWW: Server gewinnt).
  Future<void> applyServerSettings(Map<String, dynamic> settings) async {
    bool changed = false;
    if (settings.containsKey('activity_whitelist')) {
      final raw = settings['activity_whitelist'];
      if (raw is List) {
        _whitelist = List<String>.from(raw);
        changed = true;
      }
    }
    if (settings.containsKey('activity_min_duration_minutes')) {
      final v = settings['activity_min_duration_minutes'];
      if (v is int) { _minDurationMinutes = v; changed = true; }
    }
    if (settings.containsKey('activity_idle_threshold_minutes')) {
      final v = settings['activity_idle_threshold_minutes'];
      if (v is int) { _idleThresholdMinutes = v; changed = true; }
    }
    if (changed) await saveSettings();
  }

  void setMinDuration(int minutes) {
    _minDurationMinutes = minutes.clamp(1, 60);
  }

  void setIdleThreshold(int minutes) {
    _idleThresholdMinutes = minutes.clamp(1, 30);
  }

  // ── Windows tracking ──────────────────────────────────────────────────────

  void startTracking() {
    if (_isTracking) return;
    _isTracking = true;
    ActivityTrackingService.instance.startWindowsTracking(
      whitelist: _whitelist,
      idleThresholdMinutes: _idleThresholdMinutes,
      minDurationMinutes: _minDurationMinutes,
    );
    notifyListeners();
  }

  Future<void> stopTracking() async {
    if (!_isTracking) return;
    _isTracking = false;
    await ActivityTrackingService.instance.stopWindowsTracking(
      minDurationMinutes: _minDurationMinutes,
    );
    await loadSessions(_selectedDate);
    notifyListeners();
  }

  // ── Session loading ───────────────────────────────────────────────────────

  Future<void> loadSessions(DateTime date) async {
    _selectedDate = date;
    if (Platform.isAndroid) {
      _sessions = await ActivityTrackingService.instance.queryAndroid(
        date: date,
        whitelist: _whitelist,
        minDurationMinutes: _minDurationMinutes,
      );
    } else if (Platform.isWindows) {
      _sessions = await DatabaseHelper.instance.getActivityLogsForDate(date);
    }
    notifyListeners();
  }

  Future<void> clearSessionsForDate(DateTime date) async {
    if (Platform.isWindows) {
      await DatabaseHelper.instance.deleteActivityLogsForDate(date);
    }
    _sessions = [];
    notifyListeners();
  }

  // ── Permission (Android) ──────────────────────────────────────────────────

  Future<void> recheckPermission() async {
    if (!Platform.isAndroid) return;
    _hasPermission = await ActivityTrackingService.instance.hasAndroidUsagePermission();
    notifyListeners();
  }

  Future<void> openUsageSettings() async {
    await ActivityTrackingService.instance.openAndroidUsageSettings();
  }
}
