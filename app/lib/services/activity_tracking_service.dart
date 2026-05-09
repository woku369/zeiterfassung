import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';
import '../models/activity_log.dart';
import 'activity_tracking_win32.dart';

const defaultWhitelist = [
  'chrome', 'firefox', 'edge', 'opera', 'brave',
  'word', 'excel', 'powerpoint', 'libreoffice', 'writer', 'calc', 'impress',
  'acrobat', 'foxit', 'sumatra',
  'outlook', 'thunderbird',
  'teams', 'zoom', 'slack',
];

class ActivityTrackingService {
  static final ActivityTrackingService instance = ActivityTrackingService._();
  ActivityTrackingService._();

  static const _channel = MethodChannel('zeiterfassung/activity');

  Timer? _pollTimer;
  String? _lastTitle;
  DateTime? _sessionStart;

  bool get isWindowsTracking => _pollTimer != null;

  // ── Windows ───────────────────────────────────────────────────────────────

  void startWindowsTracking({
    required List<String> whitelist,
    required int idleThresholdMinutes,
    required int minDurationMinutes,
  }) {
    if (!Platform.isWindows) return;
    _pollTimer?.cancel();
    _lastTitle = null;
    _sessionStart = null;
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _pollWindows(
        whitelist: whitelist,
        idleThresholdMinutes: idleThresholdMinutes,
        minDurationMinutes: minDurationMinutes,
      );
    });
  }

  Future<void> stopWindowsTracking({required int minDurationMinutes}) async {
    _pollTimer?.cancel();
    _pollTimer = null;
    await _flushSession(minDurationMinutes: minDurationMinutes);
  }

  void _pollWindows({
    required List<String> whitelist,
    required int idleThresholdMinutes,
    required int minDurationMinutes,
  }) {
    final info = Win32ActivityHelper.instance.currentWindowAndIdle();
    if (info == null) return;
    final (title, idleMs) = info;

    final isIdle = idleMs > idleThresholdMinutes * 60 * 1000;

    if (isIdle || title.isEmpty) {
      _flushSessionSync(minDurationMinutes: minDurationMinutes);
      return;
    }

    if (title != _lastTitle) {
      _flushSessionSync(minDurationMinutes: minDurationMinutes);
      if (_matchesWhitelist(title, whitelist)) {
        _lastTitle = title;
        _sessionStart = DateTime.now();
      } else {
        _lastTitle = null;
        _sessionStart = null;
      }
    }
  }

  void _flushSessionSync({required int minDurationMinutes}) {
    if (_lastTitle == null || _sessionStart == null) return;
    final title = _lastTitle!;
    final start = _sessionStart!;
    final end = DateTime.now();
    _lastTitle = null;
    _sessionStart = null;
    if (end.difference(start).inMinutes < minDurationMinutes) return;
    final log = ActivityLog(
      id: const Uuid().v4(),
      startTime: start,
      endTime: end,
      title: title,
      appName: title,
    );
    DatabaseHelper.instance.insertActivityLog(log);
  }

  Future<void> _flushSession({required int minDurationMinutes}) async {
    if (_lastTitle == null || _sessionStart == null) return;
    final title = _lastTitle!;
    final start = _sessionStart!;
    final end = DateTime.now();
    _lastTitle = null;
    _sessionStart = null;
    if (end.difference(start).inMinutes < minDurationMinutes) return;
    await DatabaseHelper.instance.insertActivityLog(ActivityLog(
      id: const Uuid().v4(),
      startTime: start,
      endTime: end,
      title: title,
      appName: title,
    ));
  }

  // ── Android ───────────────────────────────────────────────────────────────

  Future<List<ActivityLog>> queryAndroid({
    required DateTime date,
    required List<String> whitelist,
    required int minDurationMinutes,
  }) async {
    if (!Platform.isAndroid) return [];
    try {
      final List<dynamic> raw = await _channel.invokeMethod('queryUsageStats', {
        'dateMs': DateTime(date.year, date.month, date.day).millisecondsSinceEpoch,
      });
      final logs = <ActivityLog>[];
      for (final item in raw) {
        final m = Map<String, dynamic>.from(item as Map);
        final label = m['label'] as String? ?? '';
        final pkg = m['package'] as String? ?? '';
        final title = label.isNotEmpty ? label : pkg;
        final startMs = m['startMs'] as int;
        final endMs = m['endMs'] as int;
        final start = DateTime.fromMillisecondsSinceEpoch(startMs);
        final end = DateTime.fromMillisecondsSinceEpoch(endMs);
        if (end.difference(start).inMinutes < minDurationMinutes) continue;
        if (!_matchesWhitelist(title, whitelist) &&
            !_matchesWhitelist(pkg, whitelist)) continue;
        logs.add(ActivityLog(
          id: const Uuid().v4(),
          startTime: start,
          endTime: end,
          title: title,
          appName: pkg,
        ));
      }
      logs.sort((a, b) => a.startTime.compareTo(b.startTime));
      return logs;
    } on PlatformException {
      return [];
    }
  }

  Future<bool> hasCallLogPermission() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod('hasCallLogPermission') as bool;
    } on PlatformException {
      return false;
    }
  }

  Future<List<ActivityLog>> queryCallLog({required DateTime date}) async {
    if (!Platform.isAndroid) return [];
    try {
      final List<dynamic> raw = await _channel.invokeMethod('queryCallLog', {
        'dateMs': DateTime(date.year, date.month, date.day).millisecondsSinceEpoch,
      });
      final calls = <ActivityLog>[];
      for (final item in raw) {
        final m = Map<String, dynamic>.from(item as Map);
        final name = m['name'] as String? ?? '';
        final number = m['number'] as String? ?? '';
        final durationSec = (m['durationSeconds'] as num?)?.toInt() ?? 0;
        final type = (m['type'] as num?)?.toInt() ?? 0;
        final dateMs = (m['dateMs'] as num).toInt();
        final display = name.isNotEmpty ? name : number;
        final start = DateTime.fromMillisecondsSinceEpoch(dateMs);
        final end = start.add(Duration(seconds: durationSec));
        calls.add(ActivityLog(
          id: 'call_${dateMs}_$number',
          startTime: start,
          endTime: end,
          title: display,
          appName: 'phone',
          isPhoneCall: true,
          phoneNumber: number,
          callType: type,
        ));
      }
      return calls;
    } on PlatformException {
      return [];
    }
  }

  Future<bool> hasAndroidUsagePermission() async {
    if (!Platform.isAndroid) return true;
    try {
      return await _channel.invokeMethod('hasUsagePermission') as bool;
    } on PlatformException {
      return false;
    }
  }

  Future<void> openAndroidUsageSettings() async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod('openUsageSettings');
  }

  // ── Shared ────────────────────────────────────────────────────────────────

  bool _matchesWhitelist(String text, List<String> whitelist) {
    if (whitelist.isEmpty) return true;
    final lower = text.toLowerCase();
    return whitelist.any((w) => lower.contains(w.toLowerCase()));
  }
}
