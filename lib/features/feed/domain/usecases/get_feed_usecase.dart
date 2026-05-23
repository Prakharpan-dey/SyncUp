import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/feed_item.dart';
import '../repositories/feed_repository.dart';

class GetFeedUseCase {
  final FeedRepository _repo;
  GetFeedUseCase(this._repo);

  Future<Either<Failure, ({List<FeedItem> items, String? nextCursor})>> call({
    required String tab,
    String? cursor,
    int limit = 20,
  }) {
    return _repo.getFeed(tab: tab, cursor: cursor, limit: limit);
  }
}
