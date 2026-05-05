import '../models/activity_log.dart';
import '../models/time_entry.dart';
import '../models/suggested_entry.dart';
import '../models/work_type.dart';

class FusionEngine {
  static const int _clusterGapMinutes = 10;
  static const int _minDurationMinutes = 5;

  /// Generate time-entry suggestions for [date] from activity sessions
  /// and already-tracked entries.
  static List<SuggestedEntry> generate({
    required DateTime date,
    required List<ActivityLog> sessions,
    required List<TimeEntry> existingEntries,
    String? activeEmployerId,
  }) {
    if (sessions.isEmpty) return [];

    final daySessions = sessions
        .where((s) =>
            s.startTime.year == date.year &&
            s.startTime.month == date.month &&
            s.startTime.day == date.day)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    if (daySessions.isEmpty) return [];

    final dayEntries = existingEntries
        .where((e) =>
            e.date.year == date.year &&
            e.date.month == date.month &&
            e.date.day == date.day)
        .toList();

    final phoneCalls = dayEntries
        .where((e) => e.workType == WorkType.phoneCall && e.endTime != null)
        .toList();

    final clusters = _cluster(daySessions);
    final suggestions = <SuggestedEntry>[];

    for (final cluster in clusters) {
      final start = cluster.first.startTime;
      final end = cluster.last.endTime;
      final duration = end.difference(start);

      if (duration.inMinutes < _minDurationMinutes) continue;
      if (_isCovered(start, end, dayEntries)) continue;

      final callsInWindow = phoneCalls
          .where((c) =>
              c.startTime.isBefore(end) && c.endTime!.isAfter(start))
          .toList();

      final confidence = _score(duration, callsInWindow, cluster.length);
      final workType = _inferWorkType(callsInWindow, duration);
      final note = _buildNote(cluster, callsInWindow);

      suggestions.add(SuggestedEntry(
        id: SuggestedEntry.makeId(start, end),
        startTime: start,
        endTime: end,
        workType: workType,
        note: note,
        confidence: confidence,
        signals: [
          SignalType.activity,
          if (callsInWindow.isNotEmpty) SignalType.phoneCall,
        ],
        employerId: activeEmployerId,
      ));
    }

    suggestions.sort((a, b) => a.startTime.compareTo(b.startTime));
    return suggestions;
  }

  static List<List<ActivityLog>> _cluster(List<ActivityLog> sorted) {
    final clusters = <List<ActivityLog>>[];
    List<ActivityLog>? current;

    for (final s in sorted) {
      if (current == null) {
        current = [s];
      } else {
        final gapMin =
            s.startTime.difference(current.last.endTime).inMinutes;
        if (gapMin <= _clusterGapMinutes) {
          current.add(s);
        } else {
          clusters.add(current);
          current = [s];
        }
      }
    }
    if (current != null && current.isNotEmpty) clusters.add(current);
    return clusters;
  }

  // Returns true if >50 % of the [start]–[end] window is already covered
  // by existing entries (any work type).
  static bool _isCovered(
      DateTime start, DateTime end, List<TimeEntry> entries) {
    final total = end.difference(start).inMinutes;
    if (total == 0) return true;

    int covered = 0;
    for (final e in entries) {
      final entryEnd = e.endTime ?? e.startTime;
      final oStart = start.isAfter(e.startTime) ? start : e.startTime;
      final oEnd = end.isBefore(entryEnd) ? end : entryEnd;
      if (oEnd.isAfter(oStart)) {
        covered += oEnd.difference(oStart).inMinutes;
      }
    }
    return covered > total * 0.5;
  }

  static double _score(
      Duration duration, List<TimeEntry> calls, int sessionCount) {
    double s = 0.3;
    if (calls.isNotEmpty) s += 0.35;
    if (calls.length > 1) s += 0.1;
    if (duration.inMinutes >= 30) s += 0.1;
    if (duration.inMinutes >= 60) s += 0.1;
    if (sessionCount > 3) s += 0.05;
    return s.clamp(0.0, 1.0);
  }

  static WorkType _inferWorkType(
      List<TimeEntry> calls, Duration clusterDuration) {
    if (calls.isEmpty) return WorkType.homeoffice;
    final callMinutes =
        calls.fold<int>(0, (sum, c) => sum + c.endTime!.difference(c.startTime).inMinutes);
    // Majority of cluster time is calls → phoneCall, otherwise offsite/homeoffice
    return callMinutes > clusterDuration.inMinutes * 0.5
        ? WorkType.phoneCall
        : WorkType.offsite;
  }

  static String _buildNote(
      List<ActivityLog> cluster, List<TimeEntry> calls) {
    final parts = <String>[];
    if (calls.isNotEmpty) {
      parts.add(calls.length == 1 ? '1 Telefonat' : '${calls.length} Telefonate');
    }
    final appTitles = cluster.map((s) => s.title).toSet().take(2);
    parts.addAll(appTitles);
    return parts.join(' · ');
  }
}
