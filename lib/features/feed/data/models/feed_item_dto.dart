import '../../domain/entities/feed_item.dart';

class FeedItemDto {
  final String id, actorId, actorName, type, visibility, title;
  final String? actorPhotoUrl, groupId, groupName;
  final Map<String, dynamic> metadata;
  final int reactionCount;
  final bool reacted;
  final String createdAt;

  const FeedItemDto({
    required this.id,
    required this.actorId,
    required this.actorName,
    this.actorPhotoUrl,
    required this.type,
    required this.title,
    required this.metadata,
    required this.visibility,
    this.groupId,
    this.groupName,
    this.reactionCount = 0,
    this.reacted = false,
    required this.createdAt,
  });

  factory FeedItemDto.fromJson(Map<String, dynamic> json) => FeedItemDto(
        id: json['id'] as String,
        actorId: json['actor_id'] as String,
        actorName: json['actor_name'] as String? ?? 'Unknown',
        actorPhotoUrl: json['actor_photo_url'] as String?,
        type: json['type'] as String? ?? 'task_completed',
        // Previously dropped, which is why every card read "completed 1 task"
        // no matter what the server sent.
        title: json['title'] as String? ?? '',
        metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
        visibility: json['visibility'] as String? ?? 'friends',
        groupId: json['group_id'] as String?,
        groupName: json['group_name'] as String?,
        reactionCount: json['reaction_count'] as int? ?? 0,
        reacted: json['reacted'] as bool? ?? false,
        createdAt:
            json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      );

  FeedItem toDomain() {
    const typeMap = {
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
      title: title,
      metadata: metadata,
      // Unknown values fall back rather than throwing: one unrecognised
      // string would otherwise take out the whole feed page.
      visibility: FeedVisibility.values.asNameMap()[visibility] ??
          FeedVisibility.friends,
      groupId: groupId,
      groupName: groupName,
      reactionCount: reactionCount,
      reacted: reacted,
      createdAt: DateTime.parse(createdAt),
    );
  }
}
