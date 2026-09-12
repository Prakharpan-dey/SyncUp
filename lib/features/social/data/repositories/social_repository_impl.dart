import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart' hide Group;
import '../../../../core/error/failures.dart';
import '../../../../core/sync/connectivity_service.dart';
import '../../domain/entities/friendship.dart';
import '../../domain/entities/group.dart';
import '../../domain/entities/group_invite.dart';
import '../../domain/entities/group_join_request.dart';
import '../../domain/entities/group_member.dart';
import '../../domain/entities/user_summary.dart';
import '../../domain/repositories/social_repository.dart';
import '../datasources/social_remote_datasource.dart';
import '../models/user_summary_dto.dart';
import '../models/friendship_dto.dart';
import '../models/group_dto.dart';
import '../models/group_invite_dto.dart';
import '../models/group_join_request_dto.dart';
import '../models/group_member_dto.dart';

class SocialRepositoryImpl implements SocialRepository {
  final SocialRemoteDataSource _remote;
  final ConnectivityService _connectivity;

  SocialRepositoryImpl(this._remote, this._connectivity);

  /// Guard: all mutations require connectivity
  Either<Failure, Never>? _offlineGuard() {
    if (!_connectivity.isOnline) {
      return const Left(
          NetworkFailure('Connect to the internet to do this'));
    }
    return null;
  }

  /// Convert exceptions to user-friendly failures
  Failure _mapError(Object e) {
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return const ServerFailure(
              'Server is not reachable. Please try again later.');
        case DioExceptionType.connectionError:
          return const NetworkFailure(
              'Cannot connect to the server');
        default:
          final statusCode = e.response?.statusCode;
          final message =
              e.response?.data?['message'] ?? 'Something went wrong';
          return ServerFailure(message.toString(), statusCode: statusCode);
      }
    }
    return ServerFailure(e.toString());
  }

  // Users

  @override
  Future<Either<Failure, List<UserSummary>>> searchUsers(String query) async {
    final guard = _offlineGuard();
    if (guard != null) return guard;
    try {
      final data = await _remote.searchUsers(query);
      return Right(
          data.map((j) => UserSummaryDto.fromJson(j).toDomain()).toList());
    } catch (e) {
      return Left(_mapError(e));
    }
  }

  // Friends

  @override
  Future<Either<Failure, List<UserSummary>>> getFriends(String userId) async {
    try {
      final data = await _remote.getFriends(userId);
      return Right(
          data.map((j) => UserSummaryDto.fromJson(j).toDomain()).toList());
    } catch (e) {
      // Gracefully return empty list on timeout/no-backend
      if (e is DioException) return const Right([]);
      return Left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, List<Friendship>>> getPendingRequests(
      String userId) async {
    try {
      final data = await _remote.getPendingRequests(userId);
      return Right(
          data.map((j) => FriendshipDto.fromJson(j).toDomain()).toList());
    } catch (e) {
      if (e is DioException) return const Right([]);
      return Left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, Friendship>> sendFriendRequest({
    required String requesterId,
    required String receiverId,
  }) async {
    final guard = _offlineGuard();
    if (guard != null) return guard;
    try {
      // The API takes the sender from the auth token and validates the body
      // as exactly {addressee_id}. The old {requester_id, receiver_id} failed
      // that check every time, so no friend request could ever be sent.
      final data = await _remote.sendFriendRequest({'addressee_id': receiverId});
      return Right(FriendshipDto.fromJson(data).toDomain());
    } catch (e) {
      return Left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, Friendship>> respondToRequest({
    required String requestId,
    required FriendshipStatus response,
  }) async {
    final guard = _offlineGuard();
    if (guard != null) return guard;
    try {
      // The API only accepts {status: accepted|blocked}; there is no rejected
      // status, so declining sent a body it could never validate. Declining
      // is deleting the pending row, which DELETE /friends/:id allows for
      // either party. Sending `blocked` instead would silently block them.
      if (response == FriendshipStatus.rejected) {
        await _remote.removeFriend(requestId);
        return Right(FriendshipDto.fromJson(
          {'id': requestId, 'status': FriendshipStatus.rejected.name},
        ).toDomain());
      }
      final data = await _remote.respondToRequest(
          requestId, {'status': response.name});
      return Right(FriendshipDto.fromJson(data).toDomain());
    } catch (e) {
      return Left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, void>> removeFriend(String friendshipId) async {
    final guard = _offlineGuard();
    if (guard != null) return guard;
    try {
      await _remote.removeFriend(friendshipId);
      return const Right(null);
    } catch (e) {
      return Left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, void>> blockUser({
    required String userId,
    required String blockedUserId,
  }) async {
    final guard = _offlineGuard();
    if (guard != null) return guard;
    try {
      await _remote.blockUser({
        // `user_id` is the person being blocked — the API takes the blocker
        // from the auth token. Sending our own id asked it to block ourselves.
        'user_id': blockedUserId,
      });
      return const Right(null);
    } catch (e) {
      return Left(_mapError(e));
    }
  }

  // Groups

  @override
  Future<Either<Failure, List<Group>>> getGroups(String userId) async {
    try {
      final data = await _remote.getGroups(userId);
      return Right(
          data.map((j) => GroupDto.fromJson(j).toDomain()).toList());
    } catch (e) {
      if (e is DioException) return const Right([]);
      return Left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, Group>> createGroup({
    required String name,
    required String createdBy,
  }) async {
    final guard = _offlineGuard();
    if (guard != null) return guard;
    try {
      final data = await _remote.createGroup({
        'name': name,
        'created_by': createdBy,
      });
      return Right(GroupDto.fromJson(data).toDomain());
    } catch (e) {
      return Left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, Group>> getGroupDetail(String groupId) async {
    final guard = _offlineGuard();
    if (guard != null) return guard;
    try {
      final data = await _remote.getGroupDetail(groupId);
      return Right(GroupDto.fromJson(data).toDomain());
    } catch (e) {
      return Left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, List<GroupMember>>> getGroupMembers(
      String groupId) async {
    try {
      final data = await _remote.getGroupMembers(groupId);
      return Right(
          data.map((j) => GroupMemberDto.fromJson(j, groupId: groupId).toDomain()).toList());
    } catch (e) {
      if (e is DioException) return const Right([]);
      return Left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, bool>> joinGroup(
      String inviteToken, String userId) async {
    final guard = _offlineGuard();
    if (guard != null) return guard;
    try {
      final data = await _remote.joinGroup(inviteToken, userId);
      return Right(data['status'] == 'pending');
    } catch (e) {
      return Left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, List<GroupJoinRequest>>> getJoinRequests(
      String groupId) async {
    final guard = _offlineGuard();
    if (guard != null) return guard;
    try {
      final data = await _remote.getJoinRequests(groupId);
      return Right(
          data.map((j) => GroupJoinRequestDto.fromJson(j).toDomain()).toList());
    } catch (e) {
      return Left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, void>> approveJoinRequest({
    required String groupId,
    required String requestId,
  }) async {
    final guard = _offlineGuard();
    if (guard != null) return guard;
    try {
      await _remote.approveJoinRequest(groupId, requestId);
      return const Right(null);
    } catch (e) {
      return Left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, void>> rejectJoinRequest({
    required String groupId,
    required String requestId,
  }) async {
    final guard = _offlineGuard();
    if (guard != null) return guard;
    try {
      await _remote.rejectJoinRequest(groupId, requestId);
      return const Right(null);
    } catch (e) {
      return Left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, String>> inviteToGroup({
    required String groupId,
    String? username,
    String? email,
    String? userId,
  }) async {
    final guard = _offlineGuard();
    if (guard != null) return guard;
    try {
      final data = await _remote.inviteToGroup(groupId, {
        'username': ?username,
        'email': ?email,
        'user_id': ?userId,
      });
      return Right(data['status'] as String? ?? 'invited');
    } catch (e) {
      return Left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, List<SentGroupInvite>>> getGroupInvites(
      String groupId) async {
    final guard = _offlineGuard();
    if (guard != null) return guard;
    try {
      final data = await _remote.getGroupInvites(groupId);
      return Right(
          data.map((j) => SentGroupInviteDto.fromJson(j).toDomain()).toList());
    } catch (e) {
      return Left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, void>> cancelInvite({
    required String groupId,
    required String inviteId,
  }) async {
    final guard = _offlineGuard();
    if (guard != null) return guard;
    try {
      await _remote.cancelInvite(groupId, inviteId);
      return const Right(null);
    } catch (e) {
      return Left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, List<GroupInvite>>> getMyInvites() async {
    final guard = _offlineGuard();
    if (guard != null) return guard;
    try {
      final data = await _remote.getMyInvites();
      return Right(
          data.map((j) => GroupInviteDto.fromJson(j).toDomain()).toList());
    } catch (e) {
      return Left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, void>> acceptInvite(String inviteId) async {
    final guard = _offlineGuard();
    if (guard != null) return guard;
    try {
      await _remote.acceptInvite(inviteId);
      return const Right(null);
    } catch (e) {
      return Left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, void>> declineInvite(String inviteId) async {
    final guard = _offlineGuard();
    if (guard != null) return guard;
    try {
      await _remote.declineInvite(inviteId);
      return const Right(null);
    } catch (e) {
      return Left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, void>> leaveGroup(
      String groupId, String userId) async {
    final guard = _offlineGuard();
    if (guard != null) return guard;
    try {
      await _remote.leaveGroup(groupId, userId);
      return const Right(null);
    } catch (e) {
      return Left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, void>> removeMember({
    required String groupId,
    required String userId,
  }) async {
    final guard = _offlineGuard();
    if (guard != null) return guard;
    try {
      await _remote.removeMember(groupId, userId);
      return const Right(null);
    } catch (e) {
      return Left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, String>> generateInviteLink(String groupId) async {
    final guard = _offlineGuard();
    if (guard != null) return guard;
    try {
      final data = await _remote.generateInviteLink(groupId);
      return Right(data['invite_token'] as String);
    } catch (e) {
      return Left(_mapError(e));
    }
  }
}
