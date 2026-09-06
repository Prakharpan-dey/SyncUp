import 'package:flutter_test/flutter_test.dart';
import 'package:syncup/features/social/data/models/friendship_dto.dart';
import 'package:syncup/features/social/data/models/group_dto.dart';
import 'package:syncup/features/social/data/models/group_member_dto.dart';
import 'package:syncup/features/social/data/models/user_summary_dto.dart';
import 'package:syncup/features/social/domain/entities/group_member.dart';

import '../helpers/fixtures.dart';

void main() {
  group('friend list — GET /friends', () {
    /// Every list endpoint answers with a bare array. The datasource used to
    /// unwrap `res.data['friends']`, which indexes a List with a String and
    /// throws; the repository caught it and reported "no friends", so the
    /// screen was permanently empty with no error shown.
    test('the payload is a bare array, not an envelope', () {
      expect(loadFixture('friends_list'), isA<List<dynamic>>());
    });

    test('maps a friend summary', () {
      final friend =
          UserSummaryDto.fromJson(fixtureList('friends_list').first).toDomain();

      expect(friend.id, 'bbbbbbbb-2222-4222-8222-222222222222');
      expect(friend.username, 'alexdemo');
      expect(friend.displayName, 'Alex Dsouza');
      expect(friend.photoUrl, isNull);
    });
  });

  group('pending requests — GET /friends/requests', () {
    late FriendshipDto dto;

    setUp(() => dto = FriendshipDto.fromJson(fixtureList('friend_requests').first));

    /// The API inlines the requester as `display_name` / `photo_url` and never
    /// sends `receiver_id`, `requester_name` or `requester_photo_url`. Reading
    /// those straight into non-nullable fields threw and took out the screen.
    test('reads the inlined requester', () {
      final friendship = dto.toDomain();
      expect(friendship.id, 'eeeeeeee-5555-4555-8555-555555555555');
      expect(friendship.requesterId, 'ffffffff-6666-4666-8666-666666666666');
      expect(friendship.requesterName, 'Rhea Menon');
      expect(friendship.requesterPhotoUrl, isNull);
    });

    test('defaults the status the payload omits', () {
      expect(dto.toDomain().status.name, 'pending');
    });

    test('tolerates the absent addressee rather than throwing', () {
      expect(dto.toDomain().receiverId, isEmpty);
    });

    /// POST /friends/request and PATCH /friends/request/:id answer with only
    /// `{id, status}` — accepting a request went through this path and threw.
    test('parses a mutation response carrying only id and status', () {
      final result =
          FriendshipDto.fromJson({'id': 'abc', 'status': 'accepted'}).toDomain();

      expect(result.id, 'abc');
      expect(result.status.name, 'accepted');
      expect(result.requesterId, isEmpty);
    });
  });

  group('groups — GET /groups', () {
    late GroupDto dto;

    setUp(() => dto = GroupDto.fromJson(fixtureList('groups_list').first));

    /// The client calls it `createdBy`; the API calls it `owner_id`. Reading
    /// `created_by` produced null for a non-nullable field, so both creating a
    /// group and listing groups failed.
    test('maps owner_id onto createdBy', () {
      expect(dto.toDomain().createdBy, 'bbbbbbbb-2222-4222-8222-222222222222');
    });

    test('reads the member count the header renders', () {
      expect(dto.toDomain().memberCount, 3);
    });

    test('keeps the invite token when the API sends one', () {
      expect(dto.toDomain().inviteToken, '5f2c1ab9d4e37c60');
    });

    test('accepts a null invite token for a non-owner', () {
      final detail = GroupDto.fromJson(fixtureObject('group_detail')).toDomain();
      expect(detail.inviteToken, isNull);
      expect(detail.memberCount, 3);
    });

    test('still parses if member_count is missing', () {
      final json = fixtureList('groups_list').first..remove('member_count');
      expect(GroupDto.fromJson(json).toDomain().memberCount, 0);
    });
  });

  group('group members — GET /groups/:id/members', () {
    /// The rows carry no `group_id`, so the caller supplies it. Reading it off
    /// the payload gave null for a non-nullable field and threw.
    test('takes the group id from the caller', () {
      final member = GroupMemberDto.fromJson(
        fixtureList('group_members').first,
        groupId: 'dddddddd-4444-4444-8444-444444444444',
      ).toDomain();

      expect(member.groupId, 'dddddddd-4444-4444-8444-444444444444');
      expect(member.userId, 'bbbbbbbb-2222-4222-8222-222222222222');
      expect(member.displayName, 'Alex Dsouza');
    });

    /// The server's roles are `owner` and `member`; the client enum has only
    /// admin and member, so `byName('owner')` threw and blanked the list.
    test('maps the server role owner onto admin', () {
      final owner = GroupMemberDto.fromJson(
        fixtureList('group_members')[0],
        groupId: 'g',
      ).toDomain();

      expect(owner.role, GroupRole.admin);
      expect(owner.isAdmin, isTrue);
    });

    test('maps member onto member', () {
      final member = GroupMemberDto.fromJson(
        fixtureList('group_members')[1],
        groupId: 'g',
      ).toDomain();

      expect(member.role, GroupRole.member);
      expect(member.isAdmin, isFalse);
    });

    test('an unrecognised role degrades to member rather than throwing', () {
      final member = GroupMemberDto.fromJson(
        {...fixtureList('group_members').first, 'role': 'archduke'},
        groupId: 'g',
      ).toDomain();

      expect(member.role, GroupRole.member);
    });

    // A per-group sharing override used to be parsed here from a field the
    // server never sends, and read by nothing. It has been removed: group
    // membership has no sharing control behind it, and modelling one implied a
    // setting the app could not honour.
  });

  group('user search — GET /users/search', () {
    test('is a bare array of at most one exact match', () {
      final results = fixtureList('users_search');
      expect(loadFixture('users_search'), isA<List<dynamic>>());
      expect(results, hasLength(1));

      final user = UserSummaryDto.fromJson(results.first).toDomain();
      expect(user.username, 'rhea_menon');
      expect(user.displayName, 'Rhea Menon');
    });
  });
}
