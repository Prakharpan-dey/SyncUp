import 'package:equatable/equatable.dart';

enum FeedItemType {
  taskCompleted,
  streakMilestone,
  attendanceMilestone,

  /// A snapshot of one day's tasks, posted deliberately rather than emitted by
  /// the app. Its lines live in [FeedItem.metadata].
  dailyPlan,
}

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

  /// A secondary line under the title, e.g. "3 of 5 done" on a shared plan.
  ///
  /// The server has always sent this; the client used to drop it on the floor.
  final String? summary;

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
    this.summary,
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
      case FeedItemType.dailyPlan:
        return 'shared their plan';
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

  bool get isPlan => type == FeedItemType.dailyPlan;

  /// The plan's lines, as stored in [metadata]. Empty for any other card.
  ///
  /// Tolerant of a malformed payload: one bad row should not take out the
  /// whole feed page.
  List<PlanLine> get planLines {
    final raw = metadata['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((m) => PlanLine(
              title: m['title'] as String? ?? '',
              done: m['done'] == true,
            ))
        .where((l) => l.title.isNotEmpty)
        .toList();
  }

  /// How many lines the author had beyond the ones carried in [planLines].
  int get planHiddenCount {
    final total = metadata['total'];
    if (total is! int) return 0;
    final hidden = total - planLines.length;
    return hidden > 0 ? hidden : 0;
  }
}

/// One line of a shared plan.
class PlanLine {
  final String title;
  final bool done;
  const PlanLine({required this.title, required this.done});
}
