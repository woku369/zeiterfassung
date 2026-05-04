import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/employer.dart';
import '../services/sync_service.dart';

class SyncProvider extends ChangeNotifier {
  static const _prefInterval = 'sync_interval_minutes';
  static const _defaultInterval = 30;

  List<Employer> _employers = [];
  bool _isSyncing = false;
  DateTime? _lastSyncAt;
  String? _lastError;
  int _intervalMinutes = _defaultInterval;
  Timer? _periodicTimer;
  Timer? _debounceTimer;

  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncAt => _lastSyncAt;
  String? get lastError => _lastError;
  int get intervalMinutes => _intervalMinutes;

  bool get hasNasConfig =>
      _employers.any((e) => e.nasUrl?.isNotEmpty == true);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _intervalMinutes = prefs.getInt(_prefInterval) ?? _defaultInterval;
  }

  /// Called by ProxyProvider when employer list changes.
  void updateEmployers(List<Employer> employers) {
    _employers = employers;
  }

  /// Immediate sync – called on startup or manual button.
  Future<void> syncNow() async {
    _debounceTimer?.cancel();
    await _doSync();
  }

  /// Debounced sync – called after data writes (3 s delay to batch rapid ops).
  void triggerSync() {
    if (!hasNasConfig) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 3), _doSync);
  }

  /// Start repeating timer. Call once after app is ready.
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
    final configured =
        _employers.where((e) => e.nasUrl?.isNotEmpty == true).toList();
    if (configured.isEmpty || _isSyncing) return;

    _isSyncing = true;
    _lastError = null;
    notifyListeners();

    final errors = <String>[];
    for (final emp in configured) {
      try {
        final result = await SyncService.instance.sync(
          baseUrl: emp.nasUrl!,
          apiKey: emp.nasApiKey,
        );
        if (result.errors.isNotEmpty) errors.addAll(result.errors);
      } catch (e) {
        errors.add('${emp.name}: $e');
      }
    }

    _isSyncing = false;
    if (errors.isEmpty) {
      _lastSyncAt = DateTime.now();
      _lastError = null;
    } else {
      _lastError = errors.first;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _periodicTimer?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }
}
