import '../../domain/entities/app_notification.dart';

class AppNotificationDto {
  final String id, type, title, body;
  final Map<String, dynamic> metadata;
  final bool isRead;
  final String? deepLink, createdAt;

  const AppNotificationDto({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.metadata = const {},
    this.isRead = false,
    this.deepLink,
    this.createdAt,
  });

  factory AppNotificationDto.fromJson(Map<String, dynamic> json) =>
      AppNotificationDto(
        id: json['id'],
        type: json['type'] ?? 'taskReminder',
        title: json['title'] ?? '',
        body: json['body'] ?? '',
        metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
        isRead: json['is_read'] ?? false,
        deepLink: json['deep_link'],
        createdAt: json['created_at'],
      );

  AppNotification toDomain() {
    final typeMap = {
      'task_reminder': NotificationType.taskReminder,
      'attendance_warning': NotificationType.attendanceWarning,
      'friend_request': NotificationType.friendRequest,
      'reaction': NotificationType.reaction,
      'comment': NotificationType.comment,
      'daily_digest': NotificationType.dailyDigest,
    };

    return AppNotification(
      id: id,
      type: typeMap[type] ?? NotificationType.taskReminder,
      title: title,
      body: body,
      metadata: metadata,
      isRead: isRead,
      deepLink: deepLink,
      createdAt:
          createdAt != null ? DateTime.parse(createdAt!) : DateTime.now(),
    );
  }
}
