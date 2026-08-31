import 'package:equatable/equatable.dart';

enum FeedItemType { taskCompleted, streakMilestone, attendanceMilestone }

enum FeedVisibility { friends, group }

class FeedItem extends Equatable {
  final String id;
  final String actorId;
  final String actorName;
  final String? actorPhotoUrl;
  final FeedItemType type;

  /// What the actor actually did, as the server chose to phrase it.
  ///
  /// The sharing preference is applied server-side: `all` sends the real task
  /// name, `summary` sends a generic line instead. Rendering this rather than
  /// rebuilding a sentence locally is what makes that setting mean anything.
  final String title;
  final Map<String, dynamic> metadata;
  final FeedVisibility visibility;
  final String? groupId;

  /// Which group this reached the reader through; null on the friends feed.
  final String? groupName;
  final int reactionCount;

  /// Whether the signed-in reader has already reacted.
  final bool reacted;
  final DateTime createdAt;

  const FeedItem({
    required this.id,
    required this.actorId,
    required this.actorName,
    this.actorPhotoUrl,
    required this.type,
    required this.title,
    this.metadata = const {},
    required this.visibility,
    this.groupId,
    this.groupName,
    this.reactionCount = 0,
    this.reacted = false,
    required this.createdAt,
  });

  bool get isGroupItem => visibility == FeedVisibility.group;

  /// Trailing line describing the event, used when the server sent no title.
  String get fallbackSummary {
    switch (type) {
      case FeedItemType.taskCompleted:
        final count = metadata['count'] ?? 1;
        return 'completed $count task${count == 1 ? '' : 's'}';
      case FeedItemType.streakMilestone:
        final days = metadata['days'] ?? 0;
        return 'reached a $days-day streak';
      case FeedItemType.attendanceMilestone:
        final pct = metadata['percentage'] ?? 0;
        final subject = metadata['subject_name'] ?? 'a subject';
        return 'hit $pct% attendance in $subject';
    }
  }

  FeedItem copyWith({int? reactionCount, bool? reacted}) => FeedItem(
        id: id,
        actorId: actorId,
        actorName: actorName,
        actorPhotoUrl: actorPhotoUrl,
        type: type,
        title: title,
        metadata: metadata,
        visibility: visibility,
        groupId: groupId,
        groupName: groupName,
        reactionCount: reactionCount ?? this.reactionCount,
        reacted: reacted ?? this.reacted,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [id];
}
