import '../../../../core/utils/date_helpers.dart';
import '../../domain/entities/task.dart';

class TaskDto {
  final String id, userId, title, priority, status;
  final String? description, dueDate, completedAt, seriesId, dueTime,
      sharingOverride;
  final List<String> tags;

  const TaskDto({
    required this.id, required this.userId, required this.title,
    this.description, this.dueDate, required this.priority,
    required this.status, this.tags = const [], this.completedAt,
    this.seriesId, this.dueTime, this.sharingOverride,
  });

  factory TaskDto.fromJson(Map<String, dynamic> json) => TaskDto(
    id: json['id'], userId: json['user_id'], title: json['title'],
    description: json['description'], dueDate: json['due_date'],
    priority: json['priority'] ?? 'medium', status: json['status'] ?? 'pending',
    tags: List<String>.from(json['tags'] ?? []),
    completedAt: json['completed_at'],
    seriesId: json['series_id'],
    dueTime: json['due_time'],
    sharingOverride: json['sharing_override'],
  );

  /// The wire payload for `POST /tasks` and `PATCH /tasks/:id`.
  ///
  /// Optional fields are omitted when unset rather than sent as null: the API
  /// validates them with Zod `.optional()`, which accepts an absent key but
  /// rejects an explicit null. Sending `description: null` and
  /// `due_date: null` — the shape of every task created without those fields
  /// filled in — made the server answer 422, and the repository's silent catch
  /// turned that into a task that lived only on the device.
  Map<String, dynamic> toJson() => {
    'id': id, 'user_id': userId, 'title': title,
    'priority': priority, 'status': status, 'tags': tags,
    if (description != null) 'description': description,
    if (dueDate != null) 'due_date': dueDate,
    if (completedAt != null) 'completed_at': completedAt,
    if (seriesId != null) 'series_id': seriesId,
    if (dueTime != null) 'due_time': dueTime,
    if (sharingOverride != null) 'sharing_override': sharingOverride,
  };

  Task toDomain() => Task(
    id: id, userId: userId, title: title, description: description,
    dueDate: dueDate != null ? DateTime.parse(dueDate!) : null,
    priority: TaskPriority.values.byName(priority),
    status: TaskStatus.values.byName(status), tags: tags,
    completedAt: completedAt != null ? DateTime.parse(completedAt!) : null,
    seriesId: seriesId,
    dueMinutes: DateHelpers.parseApiTime(dueTime),
    sharingOverride: sharingOverride,
    createdAt: DateTime.now(), updatedAt: DateTime.now(),
  );

  factory TaskDto.fromDomain(Task t) => TaskDto(
    id: t.id, userId: t.userId, title: t.title, description: t.description,
    // Date-only: the API validates due_date as YYYY-MM-DD.
    dueDate: t.dueDate != null ? DateHelpers.formatApiDate(t.dueDate!) : null,
    priority: t.priority.name,
    status: t.status.name, tags: t.tags,
    completedAt: t.completedAt?.toIso8601String(),
    seriesId: t.seriesId,
    dueTime: t.dueMinutes != null ? DateHelpers.formatApiTime(t.dueMinutes!) : null,
    sharingOverride: t.sharingOverride,
  );
}