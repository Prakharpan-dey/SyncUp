import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../repositories/feed_repository.dart';

class CommentOnFeedUseCase {
  final FeedRepository _repo;
  CommentOnFeedUseCase(this._repo);

  Future<Either<Failure, void>> call(String feedItemId, String text) {
    if (text.trim().isEmpty) {
      return Future.value(
          const Left(ValidationFailure('Comment cannot be empty')));
    }
    return _repo.comment(feedItemId, text.trim());
  }
}
