import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../repositories/feed_repository.dart';

class ReactToFeedUseCase {
  final FeedRepository _repo;
  ReactToFeedUseCase(this._repo);

  Future<Either<Failure, ({bool reacted, int count})>> call(String feedItemId, String emoji) {
    if (emoji.trim().isEmpty) {
      return Future.value(
          const Left(ValidationFailure('Reaction cannot be empty')));
    }
    return _repo.react(feedItemId, emoji.trim());
  }
}
