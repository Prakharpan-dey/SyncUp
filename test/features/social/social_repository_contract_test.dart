import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:syncup/core/sync/connectivity_service.dart';
import 'package:syncup/features/social/data/datasources/social_remote_datasource.dart';
import 'package:syncup/features/social/data/repositories/social_repository_impl.dart';
import 'package:syncup/features/social/domain/entities/friendship.dart';

class _MockRemote extends Mock implements SocialRemoteDataSource {}

class _MockConnectivity extends Mock implements ConnectivityService {}

/// The bodies these calls send, pinned to what the API validates.
///
/// Every friend request failed with "Validation error": the client sent
/// {requester_id, receiver_id} to an endpoint that validates exactly
/// {addressee_id}. The existing social tests mock above this layer, so they
/// could not see the wire body at all.
void main() {
  late _MockRemote remote;
  late SocialRepositoryImpl repo;

  const me = 'aaaaaaaa-1111-4111-8111-111111111111';
  const them = 'bbbbbbbb-2222-4222-8222-222222222222';
  const requestId = 'cccccccc-3333-4333-8333-333333333333';

  setUpAll(() => registerFallbackValue(<String, dynamic>{}));

  setUp(() {
    remote = _MockRemote();
    final connectivity = _MockConnectivity();
    when(() => connectivity.isOnline).thenReturn(true);
    repo = SocialRepositoryImpl(remote, connectivity);
  });

  group('sending a friend request', () {
    /// POST /friends/request — sendFriendRequestSchema: {addressee_id: uuid}.
    /// The sender comes from the auth token, never the body.
    test('sends only the addressee', () async {
      when(() => remote.sendFriendRequest(any()))
          .thenAnswer((_) async => {'id': 'f1', 'status': 'pending'});

      final result =
          await repo.sendFriendRequest(requesterId: me, receiverId: them);

      expect(result.isRight(), isTrue);
      final body =
          verify(() => remote.sendFriendRequest(captureAny())).captured.single;
      expect(body, {'addressee_id': them});
    });
  });

  group('answering a friend request', () {
    /// PATCH /friends/request/:id — respondFriendRequestSchema:
    /// {status: 'accepted' | 'blocked'}.
    test('accepting sends status accepted', () async {
      when(() => remote.respondToRequest(any(), any()))
          .thenAnswer((_) async => {'id': requestId, 'status': 'accepted'});

      final result = await repo.respondToRequest(
        requestId: requestId,
        response: FriendshipStatus.accepted,
      );

      expect(result.isRight(), isTrue);
      verify(() => remote.respondToRequest(requestId, {'status': 'accepted'}))
          .called(1);
    });

    /// The API has no rejected status, so declining sent a body it could
    /// never validate. Declining deletes the pending row instead — and must
    /// not fall back to `blocked`, which would silently block the sender.
    test('declining deletes the request instead of sending a status',
        () async {
      when(() => remote.removeFriend(any())).thenAnswer((_) async {});

      final result = await repo.respondToRequest(
        requestId: requestId,
        response: FriendshipStatus.rejected,
      );

      verify(() => remote.removeFriend(requestId)).called(1);
      verifyNever(() => remote.respondToRequest(any(), any()));
      expect(
        result.getOrElse((_) => throw StateError('declining failed')).status,
        FriendshipStatus.rejected,
      );
    });
  });

  group('blocking a user', () {
    /// POST /users/block — blockUserSchema: {user_id: uuid}, where user_id is
    /// the person being blocked. Sending our own id there meant "block myself".
    test('names the person being blocked, not the blocker', () async {
      when(() => remote.blockUser(any())).thenAnswer((_) async {});

      await repo.blockUser(userId: me, blockedUserId: them);

      final body = verify(() => remote.blockUser(captureAny())).captured.single;
      expect(body, {'user_id': them});
    });
  });

  /// Joining through an invite link now files a request an admin approves.
  group('group join requests', () {
    const groupId = 'dddddddd-4444-4444-8444-444444444444';

    test('joining reports a request left waiting', () async {
      when(() => remote.joinGroup(any(), any())).thenAnswer(
          (_) async => {'group_id': groupId, 'name': 'DBMS', 'status': 'pending'});

      final result = await repo.joinGroup('tok', me);

      expect(result.getOrElse((_) => throw StateError('join failed')), isTrue);
    });

    /// Until the backend is deployed, the old server still admits outright
    /// and sends no status — the join screen must not claim it is pending.
    test('an older server that admitted outright reads as joined', () async {
      when(() => remote.joinGroup(any(), any()))
          .thenAnswer((_) async => {'group_id': groupId, 'name': 'DBMS'});

      final result = await repo.joinGroup('tok', me);

      expect(result.getOrElse((_) => throw StateError('join failed')), isFalse);
    });

    test('parses who is waiting', () async {
      when(() => remote.getJoinRequests(groupId)).thenAnswer((_) async => [
            {
              'id': requestId,
              'user_id': them,
              'username': 'rhea',
              'display_name': 'Rhea',
              'photo_url': null,
              'created_at': '2026-09-12T08:00:00.000Z',
            },
          ]);

      final list = (await repo.getJoinRequests(groupId))
          .getOrElse((_) => throw StateError('load failed'));

      expect(list.single.id, requestId);
      expect(list.single.user.id, them);
      expect(list.single.user.username, 'rhea');
      expect(list.single.user.displayName, 'Rhea');
    });

    test('approve and reject each reach their own endpoint', () async {
      when(() => remote.approveJoinRequest(any(), any())).thenAnswer((_) async {});
      when(() => remote.rejectJoinRequest(any(), any())).thenAnswer((_) async {});

      await repo.approveJoinRequest(groupId: groupId, requestId: requestId);
      await repo.rejectJoinRequest(groupId: groupId, requestId: requestId);

      verify(() => remote.approveJoinRequest(groupId, requestId)).called(1);
      verify(() => remote.rejectJoinRequest(groupId, requestId)).called(1);
    });
  });

  /// POST /groups/:id/invites — createGroupInviteSchema takes exactly one of
  /// username, email or user_id; sending two is a 422.
  group('group invites', () {
    const groupId = 'dddddddd-4444-4444-8444-444444444444';
    const inviteId = 'eeeeeeee-5555-4555-8555-555555555555';

    setUp(() {
      when(() => remote.inviteToGroup(any(), any()))
          .thenAnswer((_) async => {'status': 'invited', 'user_id': them});
    });

    test('inviting by username sends only the username', () async {
      await repo.inviteToGroup(groupId: groupId, username: 'Rhea');

      final body = verify(() => remote.inviteToGroup(groupId, captureAny()))
          .captured
          .single;
      expect(body, {'username': 'Rhea'});
    });

    test('an email or a picked friend each send their own single key',
        () async {
      await repo.inviteToGroup(groupId: groupId, email: 'rhea@example.com');
      await repo.inviteToGroup(groupId: groupId, userId: them);

      final bodies = verify(() => remote.inviteToGroup(groupId, captureAny()))
          .captured;
      expect(bodies, [
        {'email': 'rhea@example.com'},
        {'user_id': them},
      ]);
    });

    test('reports when the person was let straight in', () async {
      when(() => remote.inviteToGroup(any(), any()))
          .thenAnswer((_) async => {'status': 'member', 'user_id': them});

      final result = await repo.inviteToGroup(groupId: groupId, userId: them);

      expect(result.getOrElse((_) => 'failed'), 'member');
    });

    test('parses the invites waiting on me', () async {
      when(() => remote.getMyInvites()).thenAnswer((_) async => [
            {
              'id': inviteId,
              'group_id': groupId,
              'group_name': 'DBMS Study Group',
              'invited_by_name': 'Rhea',
              'created_at': '2026-09-12T08:00:00.000Z',
            },
          ]);

      final invites = (await repo.getMyInvites())
          .getOrElse((_) => throw StateError('load failed'));

      expect(invites.single.id, inviteId);
      expect(invites.single.groupName, 'DBMS Study Group');
      expect(invites.single.invitedByName, 'Rhea');
    });

    test('accept and decline each reach their own endpoint', () async {
      when(() => remote.acceptInvite(any())).thenAnswer((_) async {});
      when(() => remote.declineInvite(any())).thenAnswer((_) async {});

      await repo.acceptInvite(inviteId);
      await repo.declineInvite(inviteId);

      verify(() => remote.acceptInvite(inviteId)).called(1);
      verify(() => remote.declineInvite(inviteId)).called(1);
    });
  });
}
