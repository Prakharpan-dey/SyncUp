import '../../../../core/utils/date_helpers.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_series.dart';

class TaskSeriesDto {
  final String id, userId, title, priority, weekdays, startsOn;
  final String? description, dueTime, endsOn, generatedThrough;
  final List<String> tags;
  final bool active;

  const TaskSeriesDto({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.priority,
    this.tags = const [],
    required this.weekdays,
    this.dueTime,
    required this.startsOn,
    this.endsOn,
    this.active = true,
    this.generatedThrough,
  });

  factory TaskSeriesDto.fromJson(Map<String, dynamic> json) => TaskSeriesDto(
        id: json['id'],
        userId: json['user_id'],
        title: json['title'],
        description: json['description'],
        priority: json['priority'] ?? 'medium',
        tags: List<String>.from(json['tags'] ?? []),
        weekdays: json['weekdays'],
        dueTime: json['due_time'],
        startsOn: json['starts_on'],
        endsOn: json['ends_on'],
        active: json['active'] ?? true,
        generatedThrough: json['generated_through'],
      );

  /// Same no-nulls contract as [TaskDto.toJson]: the API validates optional
  /// fields with Zod `.optional()`, which rejects an explicit null with a 422.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'priority': priority,
        'tags': tags,
        'weekdays': weekdays,
        'starts_on': startsOn,
        'active': active,
        if (description != null) 'description': description,
        if (dueTime != null) 'due_time': dueTime,
        if (endsOn != null) 'ends_on': endsOn,
        if (generatedThrough != null) 'generated_through': generatedThrough,
      };

  TaskSeries toDomain() => TaskSeries(
        id: id,
        userId: userId,
        title: title,
        description: description,
        priority: TaskPriority.values.byName(priority),
        tags: tags,
        weekdays: parseWeekdays(weekdays),
        dueMinutes: DateHelpers.parseApiTime(dueTime),
        startsOn: DateTime.parse(startsOn),
        endsOn: endsOn != null ? DateTime.parse(endsOn!) : null,
        active: active,
        generatedThrough:
            generatedThrough != null ? DateTime.parse(generatedThrough!) : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  factory TaskSeriesDto.fromDomain(TaskSeries s) => TaskSeriesDto(
        id: s.id,
        userId: s.userId,
        title: s.title,
        description: s.description,
        priority: s.priority.name,
        tags: s.tags,
        weekdays: formatWeekdays(s.weekdays),
        dueTime:
            s.dueMinutes != null ? DateHelpers.formatApiTime(s.dueMinutes!) : null,
        startsOn: DateHelpers.formatApiDate(s.startsOn),
        endsOn: s.endsOn != null ? DateHelpers.formatApiDate(s.endsOn!) : null,
        active: s.active,
        generatedThrough: s.generatedThrough != null
            ? DateHelpers.formatApiDate(s.generatedThrough!)
            : null,
      );
}

/// `'1,3,5'` → `{1, 3, 5}`. Tolerates junk by dropping it rather than throwing:
/// a malformed rule should not make the whole task list unreadable.
Set<int> parseWeekdays(String csv) => csv
    .split(',')
    .map(int.tryParse)
    .whereType<int>()
    .where((d) => d >= 1 && d <= 7)
    .toSet();

/// `{5, 1, 3}` → `'1,3,5'`. Ascending, because the API validates that order.
String formatWeekdays(Set<int> days) => (days.toList()..sort()).join(',');
