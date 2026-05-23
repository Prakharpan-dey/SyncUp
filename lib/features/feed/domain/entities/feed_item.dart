import 'package:equatable/equatable.dart';

enum FeedItemType { taskCompleted, streakMilestone, attendanceMilestone }

enum FeedVisibility { friends, group }

class FeedItem extends Equatable {
  final String id;
  final String actorId;
  final String actorName;
  final String? actorPhotoUrl;
  final FeedItemType type;
  final Map<String, dynamic> metadata;
  final FeedVisibility visibility;
  final String? groupId;
  final int reactionCount;
  final int commentCount;
  final DateTime createdAt;

  const FeedItem({
    required this.id,
    required this.actorId,
    required this.actorName,
    this.actorPhotoUrl,
    required this.type,
    this.metadata = const {},
    required this.visibility,
    this.groupId,
    this.reactionCount = 0,
    this.commentCount = 0,
    required this.createdAt,
  });

  /// Human-readable summary of the feed item
  String get summary {
    switch (type) {
      case FeedItemType.taskCompleted:
        final count = metadata['count'] ?? 1;
        return 'completed $count task${count == 1 ? '' : 's'}';
      case FeedItemType.streakMilestone:
        final days = metadata['days'] ?? 0;
        return 'reached a $days-day streak! 🔥';
      case FeedItemType.attendanceMilestone:
        final pct = metadata['percentage'] ?? 0;
        final subject = metadata['subject_name'] ?? 'a subject';
        return 'hit $pct% attendance in $subject';
    }
  }

  FeedItem copyWith({int? reactionCount, int? commentCount}) => FeedItem(
        id: id,
        actorId: actorId,
        actorName: actorName,
        actorPhotoUrl: actorPhotoUrl,
        type: type,
        metadata: metadata,
        visibility: visibility,
        groupId: groupId,
        reactionCount: reactionCount ?? this.reactionCount,
        commentCount: commentCount ?? this.commentCount,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [id];
}
