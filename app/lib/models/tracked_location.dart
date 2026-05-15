import 'work_type.dart';

class TrackedLocation {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final WorkType workType;
  final bool isActive;
  final String? employerId;
  final String updatedAt;
  final String? deletedAt;

  TrackedLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 200.0,
    this.workType = WorkType.offsite,
    this.isActive = true,
    this.employerId,
    String? updatedAt,
    this.deletedAt,
  }) : updatedAt = updatedAt ?? DateTime.now().toIso8601String();

  TrackedLocation copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    double? radiusMeters,
    WorkType? workType,
    bool? isActive,
    String? employerId,
  }) =>
      TrackedLocation(
        id: id ?? this.id,
        name: name ?? this.name,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        radiusMeters: radiusMeters ?? this.radiusMeters,
        workType: workType ?? this.workType,
        isActive: isActive ?? this.isActive,
        employerId: employerId ?? this.employerId,
        updatedAt: DateTime.now().toIso8601String(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'radius_meters': radiusMeters,
        'work_type': workType.name,
        'is_active': isActive ? 1 : 0,
        'employer_id': employerId,
        'updated_at': updatedAt,
        'deleted_at': deletedAt,
      };

  factory TrackedLocation.fromMap(Map<String, dynamic> m) => TrackedLocation(
        id: m['id'] as String,
        name: m['name'] as String,
        latitude: (m['latitude'] as num).toDouble(),
        longitude: (m['longitude'] as num).toDouble(),
        radiusMeters: (m['radius_meters'] as num?)?.toDouble() ?? 200.0,
        workType: WorkType.fromString(m['work_type'] as String? ?? 'offsite'),
        isActive: (m['is_active'] as int? ?? 1) == 1,
        employerId: m['employer_id'] as String?,
        updatedAt: m['updated_at'] as String?,
        deletedAt: m['deleted_at'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'radius_m': (radiusMeters).round(),
        'work_type': workType.name,
        'is_active': isActive ? 1 : 0,
        'employer_id': employerId,
        'updated_at': updatedAt,
        'deleted_at': deletedAt,
      };
}
