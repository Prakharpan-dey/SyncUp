import 'package:flutter_test/flutter_test.dart';
import 'package:syncup/features/feed/data/models/feed_item_dto.dart';
import 'package:syncup/features/feed/domain/entities/feed_item.dart';

import '../helpers/fixtures.dart';

void main() {
  Map<String, dynamic> firstItem(String fixture) =>
      Map<String, dynamic>.from(fixtureObject(fixture)['items'][0] as Map);

  group('FeedItemDto — friends feed', () {
    late FeedItem item;

    setUp(() {
      item = FeedItemDto.fromJson(firstItem('feed_friends')).toDomain();
    });

    test('maps every field the card renders', () {
      expect(item.id, 'aaaaaaaa-1111-4111-8111-111111111111');
      expect(item.actorId, 'bbbbbbbb-2222-4222-8222-222222222222');
      expect(item.actorName, 'Alex Dsouza');
      expect(item.type, FeedItemType.taskCompleted);
      expect(item.visibility, FeedVisibility.friends);
      expect(item.reactionCount, 2);
      expect(item.reacted, isTrue);
      expect(item.createdAt, DateTime.parse('2026-08-31T06:30:00.000Z'));
    });

    /// The regression: `title` was never parsed, so every card fell back to a
    /// computed line and read "completed 1 task" whatever the task was — which
    /// also made the server's sharing tiers invisible.
    test('parses the title the server sent', () {
      expect(item.title, 'Finish DBMS assignment');
    });

    test('carries no group, so no group chip is drawn', () {
      expect(item.isGroupItem, isFalse);
      expect(item.groupName, isNull);
      expect(item.groupId, isNull);
    });
  });

  group('FeedItemDto — groups feed', () {
    late FeedItem item;

    setUp(() {
      item = FeedItemDto.fromJson(firstItem('feed_groups')).toDomain();
    });

    /// Without the name the two tabs were indistinguishable: the only marker
    /// was a 14px icon that renders identically to the friends one.
    test('names the group it arrived through', () {
      expect(item.isGroupItem, isTrue);
      expect(item.visibility, FeedVisibility.group);
      expect(item.groupName, 'DBMS Study Group');
      expect(item.groupId, 'dddddddd-4444-4444-8444-444444444444');
    });

    test('reports the viewer has not reacted', () {
      expect(item.reacted, isFalse);
      expect(item.reactionCount, 0);
    });
  });

  group('FeedItemDto — resilience', () {
    Map<String, dynamic> base() => firstItem('feed_friends');

    test('falls back to a derived line when the title is empty', () {
      final item = FeedItemDto.fromJson({...base(), 'title': ''}).toDomain();
      expect(item.title, isEmpty);
      expect(item.fallbackSummary, 'completed 1 task');
    });

    test('pluralises the fallback from metadata', () {
      final item = FeedItemDto.fromJson({
        ...base(),
        'title': '',
        'metadata': {'count': 3},
      }).toDomain();
      expect(item.fallbackSummary, 'completed 3 tasks');
    });

    /// An unrecognised enum value must not take out the whole page. `byName`
    /// threw, which is how a single bad row could blank an entire feed.
    test('unknown visibility falls back instead of throwing', () {
      final item =
          FeedItemDto.fromJson({...base(), 'visibility': 'sometime'}).toDomain();
      expect(item.visibility, FeedVisibility.friends);
    });

    test('unknown type falls back instead of throwing', () {
      final item =
          FeedItemDto.fromJson({...base(), 'type': 'moon_landing'}).toDomain();
      expect(item.type, FeedItemType.taskCompleted);
    });

    test('absent optional fields do not throw', () {
      final item = FeedItemDto.fromJson({
        'id': 'x',
        'actor_id': 'y',
        'created_at': '2026-08-31T00:00:00.000Z',
      }).toDomain();

      expect(item.actorName, 'Unknown');
      expect(item.reactionCount, 0);
      expect(item.reacted, isFalse);
      expect(item.groupName, isNull);
    });

    test('a missing reacted flag reads as not reacted', () {
      final json = base()..remove('reacted');
      expect(FeedItemDto.fromJson(json).toDomain().reacted, isFalse);
    });
  });

  group('FeedItem.copyWith', () {
    test('carries the title and group through a reaction update', () {
      final item = FeedItemDto.fromJson(firstItem('feed_groups')).toDomain();
      final updated = item.copyWith(reactionCount: 9, reacted: true);

      expect(updated.reactionCount, 9);
      expect(updated.reacted, isTrue);
      // Everything else must survive, or the card loses its title mid-toggle.
      expect(updated.title, item.title);
      expect(updated.groupName, item.groupName);
      expect(updated.actorId, item.actorId);
    });
  });
}
