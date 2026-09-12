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

  /// The repeating rule this task was generated from, or null for a one-off.
  final String? seriesId;

  /// Per-task sharing, overriding the account default.
  ///
  /// Null or 'inherit' defers to the account setting; 'none' keeps this one
  /// task private however the account is configured.
  final String? sharingOverride;

  /// Local time of day the task is due, as minutes past midnight (0..1439).
  ///
  /// Minutes rather than `TimeOfDay`, which would drag Flutter into an entity
  /// that otherwise imports only equatable, and rather than a string, which
  /// would need parsing everywhere arithmetic happens.
  final int? dueMinutes;

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
    this.seriesId,
    this.sharingOverride,
    this.dueMinutes,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isCompleted => status == TaskStatus.completed;

  bool get isRecurring => seriesId != null;

  /// Whether this task is deliberately kept out of the feed.
  bool get isPrivate => sharingOverride == 'none';

  /// The instant this is actually due.
  ///
  /// A task with no time is due at the *end* of its day, not at midnight —
  /// which is why one due today used to read "overdue" from 00:00.
  DateTime? get dueAt {
    final date = dueDate;
    if (date == null) return null;
    return DateTime(date.year, date.month, date.day)
        .add(Duration(minutes: dueMinutes ?? (23 * 60 + 59)));
  }

  bool get isOverdue {
    final at = dueAt;
    return !isCompleted && at != null && at.isBefore(DateTime.now());
  }

  /// Pass [_cleared]-defaulted fields explicitly as null to clear them.
  ///
  /// [dueDate] and [dueMinutes] use the sentinel because the edit screen has to
  /// be able to *remove* a due date or time; a plain `?? this.x` can only ever
  /// set one.
  Task copyWith({
    String? title,
    String? description,
    Object? dueDate = _cleared,
    TaskPriority? priority,
    TaskStatus? status,
    List<String>? tags,
    Object? completedAt = _cleared,
    Object? seriesId = _cleared,
    Object? sharingOverride = _cleared,
    Object? dueMinutes = _cleared,
    DateTime? updatedAt,
  }) =>
      Task(
        id: id,
        userId: userId,
        title: title ?? this.title,
        description: description ?? this.description,
        dueDate: identical(dueDate, _cleared) ? this.dueDate : dueDate as DateTime?,
        priority: priority ?? this.priority,
        status: status ?? this.status,
        tags: tags ?? this.tags,
        completedAt: identical(completedAt, _cleared)
            ? this.completedAt
            : completedAt as DateTime?,
        // Clearable: deleting a series detaches the days that were completed.
        seriesId:
            identical(seriesId, _cleared) ? this.seriesId : seriesId as String?,
        sharingOverride: identical(sharingOverride, _cleared)
            ? this.sharingOverride
            : sharingOverride as String?,
        dueMinutes:
            identical(dueMinutes, _cleared) ? this.dueMinutes : dueMinutes as int?,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );

  // Widened beyond [id]: an edited task has to compare unequal to its old self,
  // or a ListView reuses the element and renders the stale row.
  @override
  List<Object?> get props =>
      [id, title, dueDate, dueMinutes, priority, status, completedAt, seriesId,
       sharingOverride];
}
