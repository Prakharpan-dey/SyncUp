import 'package:equatable/equatable.dart';

/// Mirrors the API's `notification_type` enum, minus `daily_digest`.
///
/// The digest was a switch with nothing behind it — no producer and no
/// scheduler — so it promised a daily summary that was never sent. The value
/// remains in the Postgres enum, since dropping one is a destructive
/// migration, but nothing creates one.
enum NotificationType {
  taskReminder,
  attendanceWarning,
  friendRequest,
  reaction,
  comment,

  /// Someone asked to join a group you run, or your own request was approved.
  groupRequest,

  /// Someone invited you into a group, or accepted an invite you sent.
  groupInvite,
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
