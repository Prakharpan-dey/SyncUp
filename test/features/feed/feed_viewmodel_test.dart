import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:syncup/core/error/failures.dart';
import 'package:syncup/features/feed/di/feed_providers.dart';
import 'package:syncup/features/feed/domain/entities/feed_item.dart';
import 'package:syncup/features/feed/domain/repositories/feed_repository.dart';
import 'package:syncup/features/feed/presentation/viewmodels/feed_viewmodel.dart';

class _MockFeedRepo extends Mock implements FeedRepository {}

FeedItem item({
  String id = 'item-1',
  int reactionCount = 0,
  bool reacted = false,
  FeedVisibility visibility = FeedVisibility.friends,
  String? groupName,
}) =>
    FeedItem(
      id: id,
      actorId: 'actor-1',
      actorName: 'Alex Dsouza',
      type: FeedItemType.taskCompleted,
      title: 'Finish DBMS assignment',
      visibility: visibility,
      groupName: groupName,
      reactionCount: reactionCount,
      reacted: reacted,
      createdAt: DateTime(2026, 8, 31),
    );

void main() {
  late _MockFeedRepo repo;
  late ProviderContainer container;

  FeedViewModel vm() => container.read(feedViewModelProvider.notifier);
  FeedState state() => container.read(feedViewModelProvider);

  setUp(() {
    repo = _MockFeedRepo();
    container = ProviderContainer(
      overrides: [feedRepositoryProvider.overrideWithValue(repo)],
    );
  });

  tearDown(() => container.dispose());

  void stubFeed(List<FeedItem> items, {String? cursor}) {
    when(() => repo.getFeed(
          tab: any(named: 'tab'),
          cursor: any(named: 'cursor'),
          limit: any(named: 'limit'),
        )).thenAnswer((_) async => Right((items: items, nextCursor: cursor)));
  }

  group('reactToItem', () {
    /// Reacting is a server-side toggle now, so the client cannot infer the
    /// result. Incrementing locally — as it used to — drifts the moment anyone
    /// toggles, and would show 1 for a tap that actually removed a reaction.
    test('adopts the count the server reports rather than incrementing', () async {
      stubFeed([item(reactionCount: 5, reacted: false)]);
      await vm().loadFeed();

      when(() => repo.react('item-1', '❤️'))
          .thenAnswer((_) async => const Right((reacted: true, count: 6)));

      await vm().reactToItem('item-1', '❤️');

      expect(state().items.first.reactionCount, 6);
      expect(state().items.first.reacted, isTrue);
    });

    test('applies a decrement when the reaction was withdrawn', () async {
      stubFeed([item(reactionCount: 3, reacted: true)]);
      await vm().loadFeed();

      when(() => repo.react('item-1', '❤️'))
          .thenAnswer((_) async => const Right((reacted: false, count: 2)));

      await vm().reactToItem('item-1', '❤️');

      expect(state().items.first.reactionCount, 2);
      expect(state().items.first.reacted, isFalse);
    });

    test('touches only the item that was reacted to', () async {
      stubFeed([
        item(id: 'a', reactionCount: 1),
        item(id: 'b', reactionCount: 7),
      ]);
      await vm().loadFeed();

      when(() => repo.react('a', '❤️'))
          .thenAnswer((_) async => const Right((reacted: true, count: 2)));

      await vm().reactToItem('a', '❤️');

      expect(state().items.firstWhere((i) => i.id == 'a').reactionCount, 2);
      expect(state().items.firstWhere((i) => i.id == 'b').reactionCount, 7);
    });

    test('leaves the count alone when the call fails', () async {
      stubFeed([item(reactionCount: 4, reacted: false)]);
      await vm().loadFeed();

      when(() => repo.react('item-1', '❤️'))
          .thenAnswer((_) async => const Left(NetworkFailure('offline')));

      await vm().reactToItem('item-1', '❤️');

      expect(state().items.first.reactionCount, 4);
      expect(state().items.first.reacted, isFalse);
      expect(state().error, isNotNull);
    });

    test('preserves the title and group while updating a reaction', () async {
      stubFeed([
        item(
          visibility: FeedVisibility.group,
          groupName: 'DBMS Study Group',
        ),
      ]);
      await vm().loadFeed();

      when(() => repo.react('item-1', '❤️'))
          .thenAnswer((_) async => const Right((reacted: true, count: 1)));

      await vm().reactToItem('item-1', '❤️');

      final updated = state().items.first;
      expect(updated.title, 'Finish DBMS assignment');
      expect(updated.groupName, 'DBMS Study Group');
      expect(updated.isGroupItem, isTrue);
    });
  });

  group('switchTab', () {
    test('refetches with the new tab', () async {
      stubFeed([item()]);
      await vm().loadFeed();

      await vm().switchTab('groups');

      verify(() => repo.getFeed(
            tab: 'groups',
            cursor: any(named: 'cursor'),
            limit: any(named: 'limit'),
          )).called(1);
      expect(state().currentTab, 'groups');
    });

    /// The two tabs are separate queries with separate results; leaving the
    /// previous tab's items on screen while the new ones load would show
    /// friends activity under the groups heading.
    test('clears the previous tab’s items while loading', () async {
      stubFeed([item(id: 'friends-item')]);
      await vm().loadFeed();
      expect(state().items, hasLength(1));

      stubFeed([item(id: 'group-item')]);
      await vm().switchTab('groups');

      expect(state().items.map((i) => i.id), ['group-item']);
    });

    test('does nothing when the tab has not actually changed', () async {
      stubFeed([item()]);
      await vm().loadFeed();
      clearInteractions(repo);

      await vm().switchTab('friends');

      verifyNever(() => repo.getFeed(
            tab: any(named: 'tab'),
            cursor: any(named: 'cursor'),
            limit: any(named: 'limit'),
          ));
    });
  });

  group('loadFeed', () {
    test('records the cursor so more can be paged in', () async {
      stubFeed([item()], cursor: '2026-08-31T06:31:00.000Z');
      await vm().loadFeed();

      expect(state().hasMore, isTrue);
      expect(state().cursor, '2026-08-31T06:31:00.000Z');
    });

    test('reports no more pages when the cursor is null', () async {
      stubFeed([item()]);
      await vm().loadFeed();

      expect(state().hasMore, isFalse);
    });

    test('surfaces a failure as an error message', () async {
      when(() => repo.getFeed(
            tab: any(named: 'tab'),
            cursor: any(named: 'cursor'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async =>
              const Left(NetworkFailure('Connect to the internet to view your feed')));

      await vm().loadFeed();

      expect(state().error, contains('internet'));
      expect(state().isLoading, isFalse);
    });
  });

  group('refreshIfStale', () {
    /// Opening the Feed tab used to refetch on every tap. It now skips a
    /// reload for 30 seconds after one — but never when nothing has loaded
    /// yet or the last attempt failed.
    void verifyFetched(int times) => verify(() => repo.getFeed(
          tab: any(named: 'tab'),
          cursor: any(named: 'cursor'),
          limit: any(named: 'limit'),
        )).called(times);

    test('loads when nothing has loaded yet', () async {
      stubFeed([item()]);
      await vm().refreshIfStale();
      verifyFetched(1);
    });

    test('skips a reload within 30 seconds of the last one', () async {
      stubFeed([item()]);
      await vm().loadFeed();
      clearInteractions(repo);

      await vm().refreshIfStale(
          now: () => DateTime.now().add(const Duration(seconds: 10)));
      verifyNever(() => repo.getFeed(
            tab: any(named: 'tab'),
            cursor: any(named: 'cursor'),
            limit: any(named: 'limit'),
          ));
    });

    test('reloads once 30 seconds have passed', () async {
      stubFeed([item()]);
      await vm().loadFeed();
      clearInteractions(repo);

      await vm().refreshIfStale(
          now: () => DateTime.now().add(const Duration(seconds: 31)));
      verifyFetched(1);
    });

    test('keeps the tab it is on', () async {
      stubFeed([item()]);
      await vm().loadFeed(tab: 'groups');
      clearInteractions(repo);

      await vm().refreshIfStale(
          now: () => DateTime.now().add(const Duration(minutes: 1)));
      verify(() => repo.getFeed(
            tab: 'groups',
            cursor: any(named: 'cursor'),
            limit: any(named: 'limit'),
          )).called(1);
    });

    test('retries straight away after a failed load', () async {
      when(() => repo.getFeed(
            tab: any(named: 'tab'),
            cursor: any(named: 'cursor'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async =>
              const Left(NetworkFailure('Connect to the internet to view your feed')));
      await vm().loadFeed();
      clearInteractions(repo);

      await vm().refreshIfStale(
          now: () => DateTime.now().add(const Duration(seconds: 1)));
      verifyFetched(1);
    });
  });
}
