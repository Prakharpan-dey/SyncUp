import 'package:objectbox/objectbox.dart';

/// The local copy of a repeating task's rule.
///
/// Occurrences are ordinary [TaskOB] rows carrying `seriesId`; this holds only
/// the rule that generates them and the watermark saying how far generation has
/// reached.
@Entity()
class TaskSeriesOB {
  @Id()
  int obId = 0;

  @Unique()
  String id;

  String userId;
  String title;
  String? description;
  String priority;
  List<String> tags;

  /// ISO weekday numbers, ascending and comma-separated: `'1,3,5'` for Mon/Wed/Fri.
  /// Daily is all seven rather than a separate mode.
  String weekdaysCsv;

  /// Local time of day, minutes past midnight. Null means no reminder.
  int? dueMinutes;

  @Property(type: PropertyType.date)
  DateTime startsOn;

  @Property(type: PropertyType.date)
  DateTime? endsOn;

  /// Cleared rather than deleted when the user stops the series, so completed
  /// occurrences keep pointing at a row that explains them.
  bool active;

  /// The last day occurrences have been generated through.
  ///
  /// Only ever moves forward. That is what makes deleting a single occurrence
  /// permanent: generation never looks back past this date.
  @Property(type: PropertyType.date)
  DateTime? generatedThrough;

  bool isSynced;

  @Property(type: PropertyType.date)
  DateTime updatedAt;

  @Property(type: PropertyType.date)
  DateTime createdAt;

  TaskSeriesOB({
    this.obId = 0,
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.priority = 'medium',
    this.tags = const [],
    required this.weekdaysCsv,
    this.dueMinutes,
    required this.startsOn,
    this.endsOn,
    this.active = true,
    this.generatedThrough,
    this.isSynced = false,
    required this.updatedAt,
    required this.createdAt,
  });
}
