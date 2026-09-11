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
}
