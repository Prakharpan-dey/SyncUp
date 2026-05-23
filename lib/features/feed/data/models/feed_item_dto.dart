import '../../domain/entities/feed_item.dart';

class FeedItemDto {
  final String id, actorId, actorName, type, visibility;
  final String? actorPhotoUrl, groupId;
  final Map<String, dynamic> metadata;
  final int reactionCount, commentCount;
  final String createdAt;

  const FeedItemDto({
    required this.id,
    required this.actorId,
    required this.actorName,
    this.actorPhotoUrl,
    required this.type,
    required this.metadata,
    required this.visibility,
    this.groupId,
    this.reactionCount = 0,
    this.commentCount = 0,
    required this.createdAt,
  });

  factory FeedItemDto.fromJson(Map<String, dynamic> json) => FeedItemDto(
        id: json['id'],
        actorId: json['actor_id'],
        actorName: json['actor_name'] ?? 'Unknown',
        actorPhotoUrl: json['actor_photo_url'],
        type: json['type'] ?? 'task_completed',
        metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
        visibility: json['visibility'] ?? 'friends',
        groupId: json['group_id'],
        reactionCount: json['reaction_count'] ?? 0,
        commentCount: json['comment_count'] ?? 0,
        createdAt: json['created_at'] ?? DateTime.now().toIso8601String(),
      );

  FeedItem toDomain() {
    // Map snake_case type strings to enum values
    final typeMap = {
      'task_completed': FeedItemType.taskCompleted,
      'streak_milestone': FeedItemType.streakMilestone,
      'attendance_milestone': FeedItemType.attendanceMilestone,
    };

    return FeedItem(
      id: id,
      actorId: actorId,
      actorName: actorName,
      actorPhotoUrl: actorPhotoUrl,
      type: typeMap[type] ?? FeedItemType.taskCompleted,
      metadata: metadata,
      visibility: FeedVisibility.values.byName(visibility),
      groupId: groupId,
      reactionCount: reactionCount,
      commentCount: commentCount,
      createdAt: DateTime.parse(createdAt),
    );
  }
}
