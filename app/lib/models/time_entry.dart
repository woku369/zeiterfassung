import 'work_type.dart';

class TimeEntry {
  final String id;
  final DateTime date;
  final DateTime startTime;
  final DateTime? endTime;
  final int breakMinutes;
  final WorkType workType;
  final DayType dayType;
  final String note;
  final double? distanceKm;
  final double? startLat;
  final double? startLng;
  final double? endLat;
  final double? endLng;
  final int travelMinutes;
  final String? employerId;
  final bool isSynced;
  final DateTime createdAt;

  const TimeEntry({
    required this.id,
    required this.date,
    required this.startTime,
    this.endTime,
    this.breakMinutes = 0,
    this.workType = WorkType.homeoffice,
    this.dayType = DayType.workday,
    this.note = '',
    this.distanceKm,
    this.startLat,
    this.startLng,
    this.endLat,
    this.endLng,
    this.travelMinutes = 0,
    this.employerId,
    this.isSynced = false,
    required this.createdAt,
  });

  Duration get totalDuration {
    if (workType.isAbsence) return Duration.zero;
    if (endTime == null) return Duration.zero;
    final raw = endTime!.difference(startTime);
    final net = raw - Duration(minutes: breakMinutes);
    return net.isNegative ? Duration.zero : net;
  }

  double get totalHours => totalDuration.inMinutes / 60.0;

  bool get isActive => !workType.isAbsence && endTime == null;

  TimeEntry copyWith({
    String? id,
    DateTime? date,
    DateTime? startTime,
    DateTime? endTime,
    int? breakMinutes,
    WorkType? workType,
    DayType? dayType,
    String? note,
    double? distanceKm,
    double? startLat,
    double? startLng,
    double? endLat,
    double? endLng,
    int? travelMinutes,
    String? employerId,
    bool? isSynced,
    DateTime? createdAt,
  }) {
    return TimeEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      breakMinutes: breakMinutes ?? this.breakMinutes,
      workType: workType ?? this.workType,
      dayType: dayType ?? this.dayType,
      note: note ?? this.note,
      distanceKm: distanceKm ?? this.distanceKm,
      startLat: startLat ?? this.startLat,
      startLng: startLng ?? this.startLng,
      endLat: endLat ?? this.endLat,
      endLng: endLng ?? this.endLng,
      travelMinutes: travelMinutes ?? this.travelMinutes,
      employerId: employerId ?? this.employerId,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'date': date.toIso8601String().substring(0, 10),
    'start_time': startTime.toIso8601String(),
    'end_time': endTime?.toIso8601String(),
    'break_minutes': breakMinutes,
    'work_type': workType.name,
    'day_type': dayType.name,
    'note': note,
    'distance_km': distanceKm,
    'start_lat': startLat,
    'start_lng': startLng,
    'end_lat': endLat,
    'end_lng': endLng,
    'travel_minutes': travelMinutes,
    'employer_id': employerId,
    'is_synced': isSynced ? 1 : 0,
    'created_at': createdAt.toIso8601String(),
  };

  factory TimeEntry.fromMap(Map<String, dynamic> m) => TimeEntry(
    id: m['id'] as String,
    date: DateTime.parse(m['date'] as String),
    startTime: DateTime.parse(m['start_time'] as String),
    endTime: m['end_time'] != null ? DateTime.parse(m['end_time'] as String) : null,
    breakMinutes: m['break_minutes'] as int? ?? 0,
    workType: WorkType.fromString(m['work_type'] as String? ?? 'homeoffice'),
    dayType: DayType.fromString(m['day_type'] as String? ?? 'workday'),
    note: m['note'] as String? ?? '',
    distanceKm: (m['distance_km'] as num?)?.toDouble(),
    startLat: (m['start_lat'] as num?)?.toDouble(),
    startLng: (m['start_lng'] as num?)?.toDouble(),
    endLat: (m['end_lat'] as num?)?.toDouble(),
    endLng: (m['end_lng'] as num?)?.toDouble(),
    travelMinutes: m['travel_minutes'] as int? ?? 0,
    employerId: m['employer_id'] as String?,
    isSynced: (m['is_synced'] as int? ?? 0) == 1,
    createdAt: DateTime.parse(m['created_at'] as String),
  );

  Map<String, dynamic> toJson() => toMap()
    ..update('is_synced', (_) => isSynced)
    ..update('end_time', (_) => endTime?.toIso8601String());

  factory TimeEntry.fromJson(Map<String, dynamic> json) {
    final m = Map<String, dynamic>.from(json);
    if (m['is_synced'] is bool) m['is_synced'] = (m['is_synced'] as bool) ? 1 : 0;
    return TimeEntry.fromMap(m);
  }
}
