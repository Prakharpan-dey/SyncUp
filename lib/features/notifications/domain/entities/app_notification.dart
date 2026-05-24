import 'package:equatable/equatable.dart';

enum NotificationType {
  taskReminder,
  attendanceWarning,
  friendRequest,
  reaction,
  comment,
  dailyDigest,
}

class AppNotification extends Equatable {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> metadata;
  final bool isRead;
  final String? deepLink;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.metadata = const {},
    this.isRead = false,
    this.deepLink,
    required this.createdAt,
  });

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        type: type,
        title: title,
        body: body,
        metadata: metadata,
        isRead: isRead ?? this.isRead,
        deepLink: deepLink,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [id];
}
