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
    this.isSynced = false,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) : updatedAt = updatedAt ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now();
}
