import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/friendship.dart';
import '../repositories/social_repository.dart';

class ManageFriendRequestUseCase {
  final SocialRepository _repo;
  ManageFriendRequestUseCase(this._repo);

  Future<Either<Failure, Friendship>> call({
    required String requestId,
    required FriendshipStatus response,
  }) async {
    if (response != FriendshipStatus.accepted &&
        response != FriendshipStatus.rejected) {
      return const Left(
          ValidationFailure('Response must be accepted or rejected'));
    }
    return _repo.respondToRequest(
      requestId: requestId,
      response: response,
    );
  }
}
