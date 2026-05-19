import 'package:uuid/uuid.dart';

class EntryProjectSplit {
  final String id;
  final String entryId;
  final String projectId;
  final int minutes;
  final String createdAt;
  final String updatedAt;

  const EntryProjectSplit({
    required this.id,
    required this.entryId,
    required this.projectId,
    required this.minutes,
    required this.createdAt,
    required this.updatedAt,
  });

  static EntryProjectSplit create({
    required String entryId,
    required String projectId,
    required int minutes,
  }) {
    final now = DateTime.now().toIso8601String();
    return EntryProjectSplit(
      id: const Uuid().v4(),
      entryId: entryId,
      projectId: projectId,
      minutes: minutes,
      createdAt: now,
      updatedAt: now,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'entry_id': entryId,
        'project_id': projectId,
        'minutes': minutes,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  factory EntryProjectSplit.fromMap(Map<String, dynamic> m) => EntryProjectSplit(
        id: m['id'] as String,
        entryId: m['entry_id'] as String,
        projectId: m['project_id'] as String,
        minutes: m['minutes'] as int? ?? 0,
        createdAt: m['created_at'] as String? ?? DateTime.now().toIso8601String(),
        updatedAt: m['updated_at'] as String? ?? DateTime.now().toIso8601String(),
      );

  Map<String, dynamic> toJson() => toMap();
  factory EntryProjectSplit.fromJson(Map<String, dynamic> json) =>
      EntryProjectSplit.fromMap(json);
}
