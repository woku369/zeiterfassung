import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/sync_service.dart';
import 'activity_provider.dart';

class SyncProvider extends ChangeNotifier {
  static const _prefInterval = 'sync_interval_minutes';
  static const _prefNasUrl   = 'global_nas_url';
  static const _prefNasKey   = 'global_nas_api_key';
  static const _defaultInterval = 30;

  bool _isSyncing = false;
  DateTime? _lastSyncAt;
  String? _lastError;
  int _intervalMinutes = _defaultInterval;
  String _nasUrl = '';
  String _nasApiKey = '';
  Timer? _periodicTimer;
  Timer? _debounceTimer;
  ActivityProvider? _activityProvider;

  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncAt => _lastSyncAt;
  String? get lastError => _lastError;
  int get intervalMinutes => _intervalMinutes;
  String get nasUrl => _nasUrl;
  String get nasApiKey => _nasApiKey;
  bool get hasNasConfig => _nasUrl.isNotEmpty;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _intervalMinutes = prefs.getInt(_prefInterval) ?? _defaultInterval;
    _nasUrl  = prefs.getString(_prefNasUrl)  ?? '';
    _nasApiKey = prefs.getString(_prefNasKey) ?? '';
  }

  void setActivityProvider(ActivityProvider ap) {
    _activityProvider = ap;
  }

  Future<void> saveNasConfig(String url, String apiKey) async {
    _nasUrl    = url.trim();
    _nasApiKey = apiKey.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefNasUrl, _nasUrl);
    await prefs.setString(_prefNasKey, _nasApiKey);
    notifyListeners();
  }

  Future<bool> testConnection() async {
    if (!hasNasConfig) return false;
    return SyncService.instance.testConnection(
      baseUrl: _nasUrl,
      apiKey: _nasApiKey.isEmpty ? null : _nasApiKey,
    );
  }

  /// Immediate sync – called on startup or manual button.
  Future<void> syncNow() async {
    _debounceTimer?.cancel();
    await _doSync();
  }

  /// Debounced sync after data writes (3 s delay to batch rapid ops).
  void triggerSync() {
    if (!hasNasConfig) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 3), _doSync);
  }

  void startPeriodicSync() {
    _periodicTimer?.cancel();
    if (_intervalMinutes <= 0) return;
    _periodicTimer = Timer.periodic(
      Duration(minutes: _intervalMinutes),
      (_) => _doSync(),
    );
  }

  Future<void> setInterval(int minutes) async {
    _intervalMinutes = minutes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefInterval, minutes);
    startPeriodicSync();
    notifyListeners();
  }

  Future<void> _doSync() async {
    if (!hasNasConfig || _isSyncing) return;
    _isSyncing = true;
    _lastError = null;
    notifyListeners();

    try {
      // Lokale Settings für den Sync einsammeln
      Map<String, dynamic>? localSettings;
      if (_activityProvider != null) {
        final ap = _activityProvider!;
        final now = DateTime.now().toIso8601String();
        localSettings = {
          'activity_whitelist': {'value': ap.whitelist, 'updated_at': now},
          'activity_min_duration_minutes': {'value': ap.minDurationMinutes, 'updated_at': now},
          'activity_idle_threshold_minutes': {'value': ap.idleThresholdMinutes, 'updated_at': now},
        };
      }

      final result = await SyncService.instance.sync(
        baseUrl: _nasUrl,
        apiKey: _nasApiKey.isEmpty ? null : _nasApiKey,
        localSettings: localSettings,
      );
      _lastError = result.errors.isEmpty ? null : result.errors.first;
      if (_lastError == null) _lastSyncAt = DateTime.now();

      // Server-Settings anwenden (NAS ist master)
      if (result.serverSettings != null && _activityProvider != null) {
        await _activityProvider!.applyServerSettings(result.serverSettings!);
      }
    } catch (e) {
      _lastError = e.toString();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _periodicTimer?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }
}
