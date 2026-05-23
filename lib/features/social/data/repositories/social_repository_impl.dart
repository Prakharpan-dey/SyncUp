import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart' hide Group;
import '../../../../core/error/failures.dart';
import '../../../../core/sync/connectivity_service.dart';
import '../../domain/entities/friendship.dart';
import '../../domain/entities/group.dart';
import '../../domain/entities/group_member.dart';
import '../../domain/entities/user_summary.dart';
import '../../domain/repositories/social_repository.dart';
import '../datasources/social_remote_datasource.dart';
import '../models/user_summary_dto.dart';
import '../models/friendship_dto.dart';
import '../models/group_dto.dart';
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
      final data = await _remote.sendFriendRequest({
        'requester_id': requesterId,
        'receiver_id': receiverId,
      });
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
        'user_id': userId,
        'blocked_user_id': blockedUserId,
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
          data.map((j) => GroupMemberDto.fromJson(j).toDomain()).toList());
    } catch (e) {
      if (e is DioException) return const Right([]);
      return Left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, void>> joinGroup(
      String inviteToken, String userId) async {
    final guard = _offlineGuard();
    if (guard != null) return guard;
    try {
      await _remote.joinGroup(inviteToken, userId);
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
