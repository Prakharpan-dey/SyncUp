import 'package:objectbox/objectbox.dart';

@Entity()
class TaskOB {
  @Id()
  int obId = 0;
  @Unique()
  String id;
  String userId;
  String title;
  String? description;
  @Property(type: PropertyType.date)
  DateTime? dueDate;
  String priority; // 'high' | 'medium' | 'low'
  String status; // 'pending' | 'completed'
  List<String> tags;
  @Property(type: PropertyType.date)
  DateTime? completedAt;

  /// The repeating rule this task was generated from, or null for a one-off.
  String? seriesId;

  /// Local time of day the task is due, as minutes past midnight (0..1439).
  ///
  /// Minutes rather than a `DateTime` or a string: it stores natively, needs no
  /// parsing at the three call sites that do arithmetic on it, and cannot hold
  /// a nonsense value like 25:99.
  int? dueMinutes;
  bool isSynced;
  @Property(type: PropertyType.date)
  DateTime updatedAt;
  @Property(type: PropertyType.date)
  DateTime createdAt;

  TaskOB({
    this.obId = 0,
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.dueDate,
    this.priority = 'medium',
    this.status = 'pending',
    this.tags = const [],
    this.completedAt,
    this.seriesId,
    this.dueMinutes,
    this.isSynced = false,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) : updatedAt = updatedAt ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now();
}
