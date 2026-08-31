import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncup/features/feed/domain/entities/feed_item.dart';
import 'package:syncup/features/feed/presentation/widgets/feed_item_card.dart';

import '../../helpers/pump.dart';

FeedItem item({
  String title = 'Finish DBMS assignment',
  FeedVisibility visibility = FeedVisibility.friends,
  String? groupName,
  int reactionCount = 0,
  bool reacted = false,
  Map<String, dynamic> metadata = const {},
}) =>
    FeedItem(
      id: 'item-1',
      actorId: 'actor-1',
      actorName: 'Alex Dsouza',
      type: FeedItemType.taskCompleted,
      title: title,
      metadata: metadata,
      visibility: visibility,
      groupName: groupName,
      reactionCount: reactionCount,
      reacted: reacted,
      createdAt: DateTime.now(),
    );

void main() {
  group('what the card says happened', () {
    /// The card used to build its own sentence from metadata and read
    /// "completed 1 task" for everything, discarding the title the server sent
    /// — which also made the sharing settings invisible.
    testWidgets('renders the title the server sent', (tester) async {
      await pumpApp(tester, FeedItemCard(item: item()));

      expect(find.textContaining('Finish DBMS assignment'), findsOneWidget);
      expect(find.textContaining('completed 1 task'), findsNothing);
    });

    testWidgets('falls back to a derived line when there is no title',
        (tester) async {
      await pumpApp(
        tester,
        FeedItemCard(item: item(title: '', metadata: const {'count': 2})),
      );

      expect(find.textContaining('completed 2 tasks'), findsOneWidget);
    });

    testWidgets('names the actor', (tester) async {
      await pumpApp(tester, FeedItemCard(item: item()));
      expect(find.text('Alex Dsouza'), findsWidgets);
    });
  });

  group('telling the two feeds apart', () {
    /// The only marker used to be a 14px icon that renders identically to the
    /// friends one, so the tabs were indistinguishable. The group's name is now
    /// on the card.
    testWidgets('a group item names its group', (tester) async {
      await pumpApp(
        tester,
        FeedItemCard(
          item: item(
            visibility: FeedVisibility.group,
            groupName: 'DBMS Study Group',
          ),
        ),
      );

      expect(find.text('DBMS Study Group'), findsOneWidget);
    });

    testWidgets('a friends item shows no group chip', (tester) async {
      await pumpApp(tester, FeedItemCard(item: item()));

      expect(find.byIcon(Icons.groups_rounded), findsNothing);
    });

    testWidgets('a group item with no name resolved shows no chip',
        (tester) async {
      await pumpApp(
        tester,
        FeedItemCard(item: item(visibility: FeedVisibility.group)),
      );

      expect(find.byIcon(Icons.groups_rounded), findsNothing);
    });
  });

  group('the react control', () {
    /// The label is always a count. Swapping between the word "REACT" and a
    /// digit changed the chip's width by ~50px, which was enough to ellipsise
    /// the group name on unreacted cards but not on the rest.
    testWidgets('shows a zero rather than the word REACT', (tester) async {
      await pumpApp(tester, FeedItemCard(item: item(reactionCount: 0)));

      expect(find.text('0'), findsOneWidget);
      expect(find.text('REACT'), findsNothing);
    });

    testWidgets('shows an outlined heart when the viewer has not reacted',
        (tester) async {
      await pumpApp(tester, FeedItemCard(item: item(reacted: false)));

      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
      expect(find.byIcon(Icons.favorite_rounded), findsNothing);
    });

    testWidgets('shows a filled heart once the viewer has reacted',
        (tester) async {
      await pumpApp(
        tester,
        FeedItemCard(item: item(reacted: true, reactionCount: 3)),
      );

      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('reports a tap', (tester) async {
      var taps = 0;
      await pumpApp(
        tester,
        FeedItemCard(item: item(), onReact: () => taps++),
      );

      await tester.tap(find.byIcon(Icons.favorite_border_rounded));
      await tester.pump();

      expect(taps, 1);
    });
  });

  group('commenting is gone', () {
    testWidgets('offers no comment control', (tester) async {
      await pumpApp(tester, FeedItemCard(item: item()));

      expect(find.text('COMMENT'), findsNothing);
      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsNothing);
    });
  });
}
