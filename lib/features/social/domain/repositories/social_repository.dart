import 'package:fpdart/fpdart.dart' hide Group;
import '../../../../core/error/failures.dart';
import '../entities/friendship.dart';
import '../entities/group.dart';
import '../entities/group_invite.dart';
import '../entities/group_join_request.dart';
import '../entities/group_member.dart';
import '../entities/user_summary.dart';

abstract interface class SocialRepository {
  // Users
  Future<Either<Failure, List<UserSummary>>> searchUsers(String query);

  // Friends
  Future<Either<Failure, List<UserSummary>>> getFriends(String userId);
  Future<Either<Failure, List<Friendship>>> getPendingRequests(String userId);
  Future<Either<Failure, Friendship>> sendFriendRequest({
    required String requesterId,
    required String receiverId,
  });
  Future<Either<Failure, Friendship>> respondToRequest({
    required String requestId,
    required FriendshipStatus response,
  });
  Future<Either<Failure, void>> removeFriend(String friendshipId);
  Future<Either<Failure, void>> blockUser({
    required String userId,
    required String blockedUserId,
  });

  // Groups
  Future<Either<Failure, List<Group>>> getGroups(String userId);
  Future<Either<Failure, Group>> createGroup({
    required String name,
    required String createdBy,
  });
  Future<Either<Failure, Group>> getGroupDetail(String groupId);
  Future<Either<Failure, List<GroupMember>>> getGroupMembers(String groupId);

  /// Right(true) when the request now waits for an admin; Right(false) when
  /// an older server admitted the user outright.
  Future<Either<Failure, bool>> joinGroup(String inviteToken, String userId);
  Future<Either<Failure, List<GroupJoinRequest>>> getJoinRequests(
    String groupId,
  );
  Future<Either<Failure, void>> approveJoinRequest({
    required String groupId,
    required String requestId,
  });
  Future<Either<Failure, void>> rejectJoinRequest({
    required String groupId,
    required String requestId,
  });
  Future<Either<Failure, void>> leaveGroup(String groupId, String userId);
  Future<Either<Failure, void>> removeMember({
    required String groupId,
    required String userId,
  });
  /// Right('invited'), or Right('member') when they had already asked to join.
  /// Exactly one of [username], [email] or [userId] names the person.
  Future<Either<Failure, String>> inviteToGroup({
    required String groupId,
    String? username,
    String? email,
    String? userId,
  });
  Future<Either<Failure, List<SentGroupInvite>>> getGroupInvites(
      String groupId);
  Future<Either<Failure, void>> cancelInvite({
    required String groupId,
    required String inviteId,
  });
  Future<Either<Failure, List<GroupInvite>>> getMyInvites();
  Future<Either<Failure, void>> acceptInvite(String inviteId);
  Future<Either<Failure, void>> declineInvite(String inviteId);
  Future<Either<Failure, String>> generateInviteLink(String groupId);
}
