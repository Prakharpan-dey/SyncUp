import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/feed_item.dart';

abstract interface class FeedRepository {
  /// Cursor-based pagination. Pass null cursor for first page
  Future<Either<Failure, ({List<FeedItem> items, String? nextCursor})>> getFeed({
    required String tab,
    String? cursor,
    int limit = 20,
  });

  /// Shares a snapshot of [date]'s tasks with the author's friends.
  ///
  /// Friends only — a plan never reaches a group.
  Future<Either<Failure, FeedItem>> sharePlan({
    required String date,
    required List<({String title, bool done})> items,
  });

  /// Toggles this user's reaction, returning (reacted, count) as recorded.
  Future<Either<Failure, ({bool reacted, int count})>> react(
      String feedItemId, String emoji);
}
