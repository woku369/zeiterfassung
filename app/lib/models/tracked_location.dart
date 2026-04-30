import 'work_type.dart';

class TrackedLocation {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final WorkType workType;
  final bool isActive;

  const TrackedLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 200.0,
    this.workType = WorkType.offsite,
    this.isActive = true,
  });

  TrackedLocation copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    double? radiusMeters,
    WorkType? workType,
    bool? isActive,
  }) =>
      TrackedLocation(
        id: id ?? this.id,
        name: name ?? this.name,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        radiusMeters: radiusMeters ?? this.radiusMeters,
        workType: workType ?? this.workType,
        isActive: isActive ?? this.isActive,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'radius_meters': radiusMeters,
        'work_type': workType.name,
        'is_active': isActive ? 1 : 0,
      };

  factory TrackedLocation.fromMap(Map<String, dynamic> m) => TrackedLocation(
        id: m['id'] as String,
        name: m['name'] as String,
        latitude: (m['latitude'] as num).toDouble(),
        longitude: (m['longitude'] as num).toDouble(),
        radiusMeters: (m['radius_meters'] as num?)?.toDouble() ?? 200.0,
        workType: WorkType.fromString(m['work_type'] as String? ?? 'offsite'),
        isActive: (m['is_active'] as int? ?? 1) == 1,
      );
}
