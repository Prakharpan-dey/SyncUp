import 'package:equatable/equatable.dart';

import 'task.dart';

/// The rule behind a repeating task.
///
/// Occurrences are ordinary [Task]s carrying [Task.seriesId]; this holds only
/// the rule and the watermark saying how far generation has reached.
class TaskSeries extends Equatable {
  final String id, userId, title;
  final String? description;
  final TaskPriority priority;
  final List<String> tags;

  /// ISO weekday numbers the task repeats on (Mon = 1), matching
  /// `DateTime.weekday`. "Daily" is all seven rather than a separate mode, so
  /// expansion never special-cases it.
  final Set<int> weekdays;

  /// Local time of day, minutes past midnight. Null means no reminder.
  final int? dueMinutes;

  final DateTime startsOn;

  /// Null means open-ended.
  final DateTime? endsOn;

  /// Cleared rather than deleted when the user stops the series, so completed
  /// occurrences keep pointing at a row that explains them.
  final bool active;

  /// The last day occurrences have been generated through.
  ///
  /// Only ever moves forward. That is what makes deleting one occurrence
  /// permanent — generation never looks back past this date.
  final DateTime? generatedThrough;

  final DateTime createdAt, updatedAt;

  const TaskSeries({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.priority = TaskPriority.medium,
    this.tags = const [],
    required this.weekdays,
    this.dueMinutes,
    required this.startsOn,
    this.endsOn,
    this.active = true,
    this.generatedThrough,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isDaily => weekdays.length == 7;

  bool repeatsOn(DateTime day) => weekdays.contains(day.weekday);

  static const _cleared = Object();

  TaskSeries copyWith({
    String? title,
    String? description,
    TaskPriority? priority,
    List<String>? tags,
    Set<int>? weekdays,
    Object? dueMinutes = _cleared,
    DateTime? startsOn,
    Object? endsOn = _cleared,
    bool? active,
    Object? generatedThrough = _cleared,
    DateTime? updatedAt,
  }) =>
      TaskSeries(
        id: id,
        userId: userId,
        title: title ?? this.title,
        description: description ?? this.description,
        priority: priority ?? this.priority,
        tags: tags ?? this.tags,
        weekdays: weekdays ?? this.weekdays,
        dueMinutes:
            identical(dueMinutes, _cleared) ? this.dueMinutes : dueMinutes as int?,
        startsOn: startsOn ?? this.startsOn,
        endsOn: identical(endsOn, _cleared) ? this.endsOn : endsOn as DateTime?,
        active: active ?? this.active,
        generatedThrough: identical(generatedThrough, _cleared)
            ? this.generatedThrough
            : generatedThrough as DateTime?,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );

  @override
  List<Object?> get props =>
      [id, title, weekdays, dueMinutes, active, endsOn, generatedThrough];
}
