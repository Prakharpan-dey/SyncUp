import 'package:objectbox/objectbox.dart';

@Entity()
class SyncQueueItemOB {
  @Id()
  int obId = 0;
  String operationType; // 'CREATE' | 'UPDATE' | 'DELETE'
  String entityType; // 'task' | 'subject' | 'attendance_session'
  String entityId;
  String payloadJson;
  int retryCount;
  String status; // 'pending' | 'in_flight' | 'failed'
  @Property(type: PropertyType.date)
  DateTime createdAt;

  SyncQueueItemOB({
    this.obId = 0,
    required this.operationType,
    required this.entityType,
    required this.entityId,
    required this.payloadJson,
    this.retryCount = 0,
    this.status = 'pending',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
