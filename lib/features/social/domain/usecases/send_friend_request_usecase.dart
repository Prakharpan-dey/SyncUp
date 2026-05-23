import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/friendship.dart';
import '../repositories/social_repository.dart';

class SendFriendRequestUseCase {
  final SocialRepository _repo;
  SendFriendRequestUseCase(this._repo);

  Future<Either<Failure, Friendship>> call({
    required String requesterId,
    required String receiverId,
  }) async {
    if (requesterId == receiverId) {
      return const Left(
          ValidationFailure('You cannot send a friend request to yourself'));
    }
    return _repo.sendFriendRequest(
      requesterId: requesterId,
      receiverId: receiverId,
    );
  }
}
