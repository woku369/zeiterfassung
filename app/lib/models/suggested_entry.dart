import 'package:uuid/uuid.dart';
import 'time_entry.dart';
import 'work_type.dart';

enum SignalType { activity, phoneCall }

class SuggestedEntry {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final WorkType workType;
  final String note;
  final double confidence;
  final List<SignalType> signals;
  final String? employerId;

  const SuggestedEntry({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.workType,
    required this.note,
    required this.confidence,
    required this.signals,
    this.employerId,
  });

  Duration get duration => endTime.difference(startTime);

  // Deterministic ID so the same time window produces the same ID across
  // multiple generate() calls, enabling persistent dismiss.
  static String makeId(DateTime start, DateTime end) {
    final s = start.toIso8601String().substring(0, 16);
    final e = end.toIso8601String().substring(0, 16);
    return 'sug_${s}_$e';
  }

  TimeEntry toPrefilledEntry() {
    final date = DateTime(startTime.year, startTime.month, startTime.day);
    return TimeEntry(
      id: const Uuid().v4(),
      date: date,
      startTime: startTime,
      endTime: endTime,
      workType: workType,
      note: note,
      employerId: employerId,
      createdAt: DateTime.now(),
    );
  }
}
