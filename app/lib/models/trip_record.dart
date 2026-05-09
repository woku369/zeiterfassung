class TripRecord {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final double startLat;
  final double startLng;
  final double? endLat;
  final double? endLng;
  final String? startAddress;
  final String? endAddress;
  final double distanceKm;
  final String? linkedEntryId;
  final String createdAt;

  const TripRecord({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.startLat,
    required this.startLng,
    this.endLat,
    this.endLng,
    this.startAddress,
    this.endAddress,
    this.distanceKm = 0,
    this.linkedEntryId,
    required this.createdAt,
  });

  bool get isComplete => endTime != null;

  Duration? get duration =>
      endTime != null ? endTime!.difference(startTime) : null;

  String get durationFormatted {
    final d = duration;
    if (d == null) return '—';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return h > 0 ? '${h}h ${m}min' : '${m}min';
  }

  TripRecord copyWith({
    String? startAddress,
    String? endAddress,
    String? linkedEntryId,
    DateTime? endTime,
    double? endLat,
    double? endLng,
    double? distanceKm,
  }) =>
      TripRecord(
        id: id,
        startTime: startTime,
        endTime: endTime ?? this.endTime,
        startLat: startLat,
        startLng: startLng,
        endLat: endLat ?? this.endLat,
        endLng: endLng ?? this.endLng,
        startAddress: startAddress ?? this.startAddress,
        endAddress: endAddress ?? this.endAddress,
        distanceKm: distanceKm ?? this.distanceKm,
        linkedEntryId: linkedEntryId ?? this.linkedEntryId,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime?.toIso8601String(),
        'start_lat': startLat,
        'start_lng': startLng,
        'end_lat': endLat,
        'end_lng': endLng,
        'start_address': startAddress,
        'end_address': endAddress,
        'distance_km': distanceKm,
        'linked_entry_id': linkedEntryId,
        'created_at': createdAt,
      };

  factory TripRecord.fromMap(Map<String, dynamic> m) => TripRecord(
        id: m['id'] as String,
        startTime: DateTime.parse(m['start_time'] as String),
        endTime: m['end_time'] != null
            ? DateTime.parse(m['end_time'] as String)
            : null,
        startLat: (m['start_lat'] as num).toDouble(),
        startLng: (m['start_lng'] as num).toDouble(),
        endLat: m['end_lat'] != null ? (m['end_lat'] as num).toDouble() : null,
        endLng: m['end_lng'] != null ? (m['end_lng'] as num).toDouble() : null,
        startAddress: m['start_address'] as String?,
        endAddress: m['end_address'] as String?,
        distanceKm: (m['distance_km'] as num? ?? 0).toDouble(),
        linkedEntryId: m['linked_entry_id'] as String?,
        createdAt: m['created_at'] as String,
      );
}
