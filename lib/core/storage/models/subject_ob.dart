import 'package:objectbox/objectbox.dart';

@Entity()
class SubjectOB {
  @Id()
  int obId = 0;
  @Unique()
  String id;
  String userId;
  String name;
  String? code;
  int thresholdPct;
  bool isSynced;
  @Property(type: PropertyType.date)
  DateTime updatedAt;

  SubjectOB({
    this.obId = 0,
    required this.id,
    required this.userId,
    required this.name,
    this.code,
    this.thresholdPct = 75,
    this.isSynced = false,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();
}
