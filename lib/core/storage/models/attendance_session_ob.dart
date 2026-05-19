import 'package:objectbox/objectbox.dart';

@Entity()
class AttendanceSessionOB {
  @Id()
  int obId = 0;
  @Unique()
  String id;
  String subjectId;
  @Property(type: PropertyType.date)
  DateTime sessionDate;
  String status; // 'present' | 'absent'
  bool isSynced;
  @Property(type: PropertyType.date)
  DateTime updatedAt;
  @Property(type: PropertyType.date)
  DateTime createdAt;

  AttendanceSessionOB({
    this.obId = 0,
    required this.id,
    required this.subjectId,
    required this.sessionDate,
    required this.status,
    this.isSynced = false,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) : updatedAt = updatedAt ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now();
}
