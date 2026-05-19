import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/activity_log.dart';
import '../database/database_helper.dart';
import '../services/activity_tracking_service.dart';

const _kDeviceName = 'device_name';

class ActivityProvider extends ChangeNotifier {
  static const _keyWhitelist = 'activity_whitelist';
  static const _keyMinDuration = 'activity_min_duration_minutes';
  static const _keyIdleThreshold = 'activity_idle_threshold_minutes';
  static const _keyAdoptedCalls    = 'activity_adopted_calls';
  static const _keyAdoptedSessions = 'activity_adopted_sessions';
  // Per-key LWW timestamps – epoch means "never changed locally".
  // Only the keys the user actually changed get a non-epoch timestamp,
  // so a device that only changes min_duration can't overwrite another
  // device's whitelist on the NAS.
  static const _keyWhitelistTs    = 'activity_whitelist_changed_at';
  static const _keyMinDurationTs  = 'activity_min_duration_changed_at';
  static const _keyIdleThresholdTs= 'activity_idle_threshold_changed_at';
  static const epochTs = '2000-01-01T00:00:00.000Z';

  List<ActivityLog> _sessions = [];
  List<ActivityLog> _calls = [];
  bool _hasCallLogPermission = false;
  final Set<String> _adoptedCallIds    = {};
  final Set<String> _adoptedSessionIds = {};
  List<String> _whitelist = List.from(defaultWhitelist);
  int _minDurationMinutes = 3;
  int _idleThresholdMinutes = 5;
  bool _isTracking = false;
  bool _hasPermission = false;
  DateTime _selectedDate = DateTime.now();
  String _deviceName = 'Dieses Gerät';
  // Per-key timestamps (start at epoch = never locally changed).
  String _whitelistTs     = epochTs;
  String _minDurationTs   = epochTs;
  String _idleThresholdTs = epochTs;
  // Track which keys were touched by the user since last save.
  final Set<String> _dirtyKeys = {};

  List<ActivityLog> get sessions => _sessions;
  List<ActivityLog> get calls => _calls;
  bool get hasCallLogPermission => _hasCallLogPermission;
  bool isCallAdopted(String id)    => _adoptedCallIds.contains(id);
  bool isSessionAdopted(String id) => _adoptedSessionIds.contains(id);
  List<String> get whitelist => _whitelist;
  int get minDurationMinutes => _minDurationMinutes;
  int get idleThresholdMinutes => _idleThresholdMinutes;
  bool get isTracking => _isTracking;
  bool get hasPermission => _hasPermission;
  DateTime get selectedDate => _selectedDate;
  String get deviceName => _deviceName;
  /// Per-key timestamps for sync payload.
  String get whitelistChangedAt     => _whitelistTs;
  String get minDurationChangedAt   => _minDurationTs;
  String get idleThresholdChangedAt => _idleThresholdTs;

  bool get isSupported => Platform.isWindows || Platform.isAndroid;

  Future<void> init() async {
    await _loadSettings();
    final prefs = await SharedPreferences.getInstance();
    _deviceName = prefs.getString(_kDeviceName) ?? _defaultHostname();
    ActivityTrackingService.instance.setDeviceName(_deviceName);
    if (Platform.isAndroid) {
      _hasPermission = await ActivityTrackingService.instance.hasAndroidUsagePermission();
      _hasCallLogPermission = await ActivityTrackingService.instance.hasCallLogPermission();
    } else {
      _hasPermission = true;
    }
    notifyListeners();
  }

  String _defaultHostname() {
    try {
      return Platform.localHostname;
    } catch (_) {
      return 'Dieses Gerät';
    }
  }

  Future<void> setDeviceName(String name) async {
    _deviceName = name.trim().isEmpty ? _defaultHostname() : name.trim();
    ActivityTrackingService.instance.setDeviceName(_deviceName);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDeviceName, _deviceName);
    notifyListeners();
  }

  Future<void> recheckCallLogPermission() async {
    if (!Platform.isAndroid) return;
    _hasCallLogPermission = await ActivityTrackingService.instance.hasCallLogPermission();
    if (_hasCallLogPermission) await loadSessions(_selectedDate);
    notifyListeners();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_keyWhitelist);
    if (saved != null) _whitelist = saved;
    _minDurationMinutes = prefs.getInt(_keyMinDuration) ?? 3;
    _idleThresholdMinutes = prefs.getInt(_keyIdleThreshold) ?? 5;
    // Load per-key timestamps; fall back to legacy single timestamp if present.
    final legacy = prefs.getString('activity_settings_changed_at');
    _whitelistTs     = prefs.getString(_keyWhitelistTs)     ?? legacy ?? epochTs;
    _minDurationTs   = prefs.getString(_keyMinDurationTs)   ?? legacy ?? epochTs;
    _idleThresholdTs = prefs.getString(_keyIdleThresholdTs) ?? legacy ?? epochTs;
    // Adopted sets
    final adoptedCalls    = prefs.getStringList(_keyAdoptedCalls);
    if (adoptedCalls != null) _adoptedCallIds.addAll(adoptedCalls);
    final adoptedSessions = prefs.getStringList(_keyAdoptedSessions);
    if (adoptedSessions != null) _adoptedSessionIds.addAll(adoptedSessions);
  }

  Future<void> markCallAdopted(String id) async {
    _adoptedCallIds.add(id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyAdoptedCalls, _adoptedCallIds.toList());
    notifyListeners();
  }

  Future<void> markSessionAdopted(String id) async {
    _adoptedSessionIds.add(id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyAdoptedSessions, _adoptedSessionIds.toList());
    notifyListeners();
  }

  /// Called when the user explicitly saves settings.
  /// Only advances the LWW timestamp for keys the user actually changed.
  Future<void> saveSettings() async {
    final now = DateTime.now().toIso8601String();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyWhitelist, _whitelist);
    await prefs.setInt(_keyMinDuration, _minDurationMinutes);
    await prefs.setInt(_keyIdleThreshold, _idleThresholdMinutes);
    if (_dirtyKeys.contains(_keyWhitelist)) {
      _whitelistTs = now;
      await prefs.setString(_keyWhitelistTs, now);
    }
    if (_dirtyKeys.contains(_keyMinDuration)) {
      _minDurationTs = now;
      await prefs.setString(_keyMinDurationTs, now);
    }
    if (_dirtyKeys.contains(_keyIdleThreshold)) {
      _idleThresholdTs = now;
      await prefs.setString(_keyIdleThresholdTs, now);
    }
    _dirtyKeys.clear();
    notifyListeners();
  }

  void setWhitelist(List<String> list) {
    _whitelist = list;
    _dirtyKeys.add(_keyWhitelist);
  }

  /// Vom NAS empfangene Settings übernehmen (LWW per Key).
  /// Übernimmt einen Wert nur wenn der NAS-Timestamp neuer ist als der lokale.
  /// Berührt die lokalen Timestamps NICHT, damit dieses Gerät beim nächsten
  /// Sync nicht seine alten Werte fälschlicherweise als "neu" deklariert.
  Future<void> applyServerSettings(Map<String, dynamic> settings) async {
    bool changed = false;
    final prefs = await SharedPreferences.getInstance();

    if (settings.containsKey('activity_whitelist')) {
      final raw = settings['activity_whitelist'];
      final serverTs = settings['activity_whitelist_updated_at'] as String? ?? epochTs;
      if (raw is List && serverTs.compareTo(_whitelistTs) > 0) {
        _whitelist = List<String>.from(raw);
        await prefs.setStringList(_keyWhitelist, _whitelist);
        changed = true;
      }
    }
    if (settings.containsKey('activity_min_duration_minutes')) {
      final v = settings['activity_min_duration_minutes'];
      final serverTs = settings['activity_min_duration_updated_at'] as String? ?? epochTs;
      if (v is int && serverTs.compareTo(_minDurationTs) > 0) {
        _minDurationMinutes = v;
        await prefs.setInt(_keyMinDuration, _minDurationMinutes);
        changed = true;
      }
    }
    if (settings.containsKey('activity_idle_threshold_minutes')) {
      final v = settings['activity_idle_threshold_minutes'];
      final serverTs = settings['activity_idle_threshold_updated_at'] as String? ?? epochTs;
      if (v is int && serverTs.compareTo(_idleThresholdTs) > 0) {
        _idleThresholdMinutes = v;
        await prefs.setInt(_keyIdleThreshold, _idleThresholdMinutes);
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  void setMinDuration(int minutes) {
    _minDurationMinutes = minutes.clamp(1, 60);
    _dirtyKeys.add(_keyMinDuration);
  }

  void setIdleThreshold(int minutes) {
    _idleThresholdMinutes = minutes.clamp(1, 30);
    _dirtyKeys.add(_keyIdleThreshold);
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
      final raw = await ActivityTrackingService.instance.queryAndroid(
        date: date,
        whitelist: _whitelist,
        minDurationMinutes: _minDurationMinutes,
      );
      // Persist this device's sessions so they sync to other devices.
      await DatabaseHelper.instance.insertActivityLogs(raw);
      // Load from DB to include pooled sessions from other devices.
      _sessions = await DatabaseHelper.instance.getActivityLogsForDate(date);
      if (_hasCallLogPermission) {
        _calls = await ActivityTrackingService.instance.queryCallLog(date: date);
      }
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
