import 'package:equatable/equatable.dart';

enum TaskPriority { high, medium, low }
enum TaskStatus { pending, completed }

/// Sentinel object used to explicitly clear a nullable field in [copyWith].
const _cleared = Object();

class Task extends Equatable {
  final String id, userId, title;
  final String? description;
  final DateTime? dueDate, completedAt;
  final TaskPriority priority;
  final TaskStatus status;
  final List<String> tags;
  final DateTime createdAt, updatedAt;

  const Task({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.dueDate,
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.pending,
    this.tags = const [],
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isCompleted => status == TaskStatus.completed;

  /// Pass [clearCompletedAt] = true to explicitly set completedAt to null.
  Task copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    TaskPriority? priority,
    TaskStatus? status,
    List<String>? tags,
    Object? completedAt = _cleared,
    DateTime? updatedAt,
  }) =>
      Task(
        id: id,
        userId: userId,
        title: title ?? this.title,
        description: description ?? this.description,
        dueDate: dueDate ?? this.dueDate,
        priority: priority ?? this.priority,
        status: status ?? this.status,
        tags: tags ?? this.tags,
        completedAt: identical(completedAt, _cleared)
            ? this.completedAt
            : completedAt as DateTime?,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );

  @override
  List<Object?> get props => [id];
}