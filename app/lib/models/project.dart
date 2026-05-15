import 'package:uuid/uuid.dart';

class Project {
  final String id;
  final String name;
  final String? employerId;
  final int sortOrder;
  final String updatedAt;
  final String? deletedAt;

  const Project({
    required this.id,
    required this.name,
    this.employerId,
    this.sortOrder = 0,
    required this.updatedAt,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  static Project create({
    required String name,
    String? employerId,
    int sortOrder = 0,
  }) =>
      Project(
        id: const Uuid().v4(),
        name: name,
        employerId: employerId,
        sortOrder: sortOrder,
        updatedAt: DateTime.now().toIso8601String(),
      );

  Project copyWith({
    String? id,
    String? name,
    String? employerId,
    int? sortOrder,
    String? updatedAt,
    String? deletedAt,
  }) =>
      Project(
        id: id ?? this.id,
        name: name ?? this.name,
        employerId: employerId ?? this.employerId,
        sortOrder: sortOrder ?? this.sortOrder,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'employer_id': employerId,
        'sort_order': sortOrder,
        'updated_at': updatedAt,
        'deleted_at': deletedAt,
      };

  factory Project.fromMap(Map<String, dynamic> m) => Project(
        id: m['id'] as String,
        name: m['name'] as String,
        employerId: m['employer_id'] as String?,
        sortOrder: m['sort_order'] as int? ?? 0,
        updatedAt: m['updated_at'] as String? ?? DateTime.now().toIso8601String(),
        deletedAt: m['deleted_at'] as String?,
      );

  Map<String, dynamic> toJson() => toMap();
  factory Project.fromJson(Map<String, dynamic> json) => Project.fromMap(json);
}
