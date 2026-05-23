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

  Future<Either<Failure, void>> react(String feedItemId, String emoji);
  Future<Either<Failure, void>> comment(String feedItemId, String text);
}
