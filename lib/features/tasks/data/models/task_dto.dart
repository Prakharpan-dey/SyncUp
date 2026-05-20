import '../../domain/entities/task.dart';

class TaskDto {
  final String id, userId, title, priority, status;
  final String? description, dueDate, completedAt;
  final List<String> tags;

  const TaskDto({
    required this.id, required this.userId, required this.title,
    this.description, this.dueDate, required this.priority,
    required this.status, this.tags = const [], this.completedAt,
  });

  factory TaskDto.fromJson(Map<String, dynamic> json) => TaskDto(
    id: json['id'], userId: json['user_id'], title: json['title'],
    description: json['description'], dueDate: json['due_date'],
    priority: json['priority'] ?? 'medium', status: json['status'] ?? 'pending',
    tags: List<String>.from(json['tags'] ?? []),
    completedAt: json['completed_at'],
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'user_id': userId, 'title': title,
    'description': description, 'due_date': dueDate,
    'priority': priority, 'status': status, 'tags': tags,
    'completed_at': completedAt,
  };

  Task toDomain() => Task(
    id: id, userId: userId, title: title, description: description,
    dueDate: dueDate != null ? DateTime.parse(dueDate!) : null,
    priority: TaskPriority.values.byName(priority),
    status: TaskStatus.values.byName(status), tags: tags,
    completedAt: completedAt != null ? DateTime.parse(completedAt!) : null,
    createdAt: DateTime.now(), updatedAt: DateTime.now(),
  );

  factory TaskDto.fromDomain(Task t) => TaskDto(
    id: t.id, userId: t.userId, title: t.title, description: t.description,
    dueDate: t.dueDate?.toIso8601String(), priority: t.priority.name,
    status: t.status.name, tags: t.tags,
    completedAt: t.completedAt?.toIso8601String(),
  );
}