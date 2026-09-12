import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' hide Group;
import 'package:mocktail/mocktail.dart';
import 'package:syncup/core/auth/current_user.dart';
import 'package:syncup/core/error/failures.dart';
import 'package:syncup/features/social/di/social_providers.dart';
import 'package:syncup/features/social/domain/entities/friendship.dart';
import 'package:syncup/features/social/domain/entities/group.dart';
import 'package:syncup/features/social/domain/entities/group_invite.dart';
import 'package:syncup/features/social/domain/entities/group_member.dart';
import 'package:syncup/features/social/domain/entities/user_summary.dart';
import 'package:syncup/features/social/domain/repositories/social_repository.dart';
import 'package:syncup/features/social/presentation/viewmodels/social_viewmodel.dart';

class _MockSocialRepo extends Mock implements SocialRepository {}

const owner = 'owner-id';
const memberA = 'member-a';
const memberB = 'member-b';
const groupId = 'group-id';

Group aGroup({int memberCount = 3}) => Group(
      id: groupId,
      name: 'DBMS Study Group',
      createdBy: owner,
      inviteToken: 'tok',
      memberCount: memberCount,
      createdAt: DateTime(2026, 8, 31),
      updatedAt: DateTime(2026, 8, 31),
    );

GroupMember member(String userId, String name) => GroupMember(
      groupId: groupId,
      userId: userId,
      displayName: name,
      role: GroupRole.member,
    );

UserSummary friend(String id, String name) =>
    UserSummary(id: id, username: name.toLowerCase(), displayName: name);

void main() {
  late _MockSocialRepo repo;
  late ProviderContainer container;

  SocialViewModel vm() => container.read(socialViewModelProvider.notifier);
  SocialState state() => container.read(socialViewModelProvider);

  setUp(() {
    repo = _MockSocialRepo();
    container = ProviderContainer(overrides: [
      socialRepositoryProvider.overrideWithValue(repo),
      currentUserIdProvider.overrideWithValue(owner),
    ]);
  });

  tearDown(() => container.dispose());

  Future<void> loadDetail() async {
    when(() => repo.getGroupDetail(groupId))
        .thenAnswer((_) async => Right(aGroup()));
    // The owner's detail view also loads anyone waiting to join, and the
    // invites the group has sent.
    when(() => repo.getJoinRequests(groupId))
        .thenAnswer((_) async => const Right([]));
    when(() => repo.getGroupInvites(groupId))
        .thenAnswer((_) async => const Right([]));
    when(() => repo.getGroupMembers(groupId)).thenAnswer((_) async => Right([
          member(owner, 'Group Owner'),
          member(memberA, 'Rhea Menon'),
          member(memberB, 'Arjun Singh'),
        ]));
    await vm().loadGroupDetail(groupId);
  }

  group('removeMember', () {
    test('drops the member from the list', () async {
      await loadDetail();
      when(() => repo.removeMember(groupId: groupId, userId: memberA))
          .thenAnswer((_) async => const Right(null));

      await vm().removeMember(groupId, memberA);

      expect(state().groupMembers.map((m) => m.userId), [owner, memberB]);
    });

    /// The header count lives on `selectedGroup`, separate from the member
    /// list, so removing someone left the card reading "3 members" above a list
    /// of two.
    test('keeps the header count in step with the list', () async {
      await loadDetail();
      expect(state().selectedGroup!.memberCount, 3);

      when(() => repo.removeMember(groupId: groupId, userId: memberA))
          .thenAnswer((_) async => const Right(null));
      await vm().removeMember(groupId, memberA);

      expect(state().selectedGroup!.memberCount, 2);
      expect(state().groupMembers, hasLength(2));
    });

    test('leaves the list alone when the server refuses', () async {
      await loadDetail();
      when(() => repo.removeMember(groupId: groupId, userId: memberA))
          .thenAnswer((_) async =>
              const Left(ServerFailure('Only the group owner can remove members')));

      await vm().removeMember(groupId, memberA);

      expect(state().groupMembers, hasLength(3));
      expect(state().selectedGroup!.memberCount, 3);
      expect(state().error, isNotNull);
    });
  });

  group('respondToRequest', () {
    Friendship request(String id) => Friendship(
          id: id,
          requesterId: memberA,
          receiverId: owner,
          status: FriendshipStatus.pending,
          requesterName: 'Rhea Menon',
          createdAt: DateTime(2026, 8, 31),
          updatedAt: DateTime(2026, 8, 31),
        );

    setUp(() {
      when(() => repo.getPendingRequests(any()))
          .thenAnswer((_) async => Right([request('r1'), request('r2')]));
    });

    test('removes the answered request', () async {
      await vm().loadPendingRequests(owner);
      when(() => repo.respondToRequest(
            requestId: 'r1',
            response: FriendshipStatus.accepted,
          )).thenAnswer((_) async => Right(request('r1')));
      when(() => repo.getFriends(any()))
          .thenAnswer((_) async => Right([friend(memberA, 'Rhea')]));

      await vm().respondToRequest(
        requestId: 'r1',
        response: FriendshipStatus.accepted,
      );

      expect(state().pendingRequests.map((r) => r.id), ['r2']);
    });

    /// Accepting creates a friendship the Friends tab reads from a separate
    /// list, so it must refetch or the tab keeps reporting the old count.
    test('reloads the friends list after accepting', () async {
      await vm().loadPendingRequests(owner);
      when(() => repo.respondToRequest(
            requestId: 'r1',
            response: FriendshipStatus.accepted,
          )).thenAnswer((_) async => Right(request('r1')));
      when(() => repo.getFriends(any()))
          .thenAnswer((_) async => Right([friend(memberA, 'Rhea')]));

      await vm().respondToRequest(
        requestId: 'r1',
        response: FriendshipStatus.accepted,
      );

      verify(() => repo.getFriends(any())).called(1);
      expect(state().friends, hasLength(1));
    });

    test('does not reload friends when the request was declined', () async {
      await vm().loadPendingRequests(owner);
      when(() => repo.respondToRequest(
            requestId: 'r1',
            response: FriendshipStatus.rejected,
          )).thenAnswer((_) async => Right(request('r1')));

      await vm().respondToRequest(
        requestId: 'r1',
        response: FriendshipStatus.rejected,
      );

      verifyNever(() => repo.getFriends(any()));
    });
  });

  group('group invites', () {
    final invite = GroupInvite(
      id: 'inv-1',
      groupId: groupId,
      groupName: 'DBMS Study Group',
      invitedByName: 'Rhea Menon',
      createdAt: DateTime(2026, 9, 12),
    );

    test('accepting drops the invite and shows the group it joined', () async {
      when(() => repo.getMyInvites()).thenAnswer((_) async => Right([invite]));
      when(() => repo.acceptInvite('inv-1'))
          .thenAnswer((_) async => const Right(null));
      when(() => repo.getGroups(owner))
          .thenAnswer((_) async => Right([aGroup()]));
      await vm().loadMyInvites();

      final joined = await vm().acceptInvite('inv-1');

      expect(joined, isTrue);
      expect(state().myInvites, isEmpty);
      expect(state().groups.single.id, groupId);
    });

    test('declining drops the invite and joins nothing', () async {
      when(() => repo.getMyInvites()).thenAnswer((_) async => Right([invite]));
      when(() => repo.declineInvite('inv-1'))
          .thenAnswer((_) async => const Right(null));
      await vm().loadMyInvites();

      await vm().declineInvite('inv-1');

      expect(state().myInvites, isEmpty);
      verifyNever(() => repo.getGroups(any()));
    });

    /// "No SyncUp account with that email" is an answer for the sheet, not a
    /// banner over the whole group screen.
    test('an unknown email comes back as the answer, not a screen error',
        () async {
      when(() => repo.inviteToGroup(
                groupId: groupId,
                email: 'nobody@example.com',
              ))
          .thenAnswer((_) async =>
              const Left(ServerFailure('No SyncUp account with that email')));

      final result = await vm()
          .inviteToGroup(groupId: groupId, email: 'nobody@example.com');

      expect(result.ok, isFalse);
      expect(result.message, 'No SyncUp account with that email');
      expect(state().error, isNull);
    });
  });
}
