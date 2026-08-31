import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:syncup/core/auth/current_user.dart';
import 'package:syncup/features/social/di/social_providers.dart';
import 'package:syncup/features/social/domain/entities/user_summary.dart';
import 'package:syncup/features/social/domain/repositories/social_repository.dart';
import 'package:syncup/features/social/presentation/screens/search_users_screen.dart';

import '../../helpers/pump.dart';

class _MockSocialRepo extends Mock implements SocialRepository {}

void main() {
  late _MockSocialRepo repo;
  late ProviderContainer container;

  setUp(() {
    repo = _MockSocialRepo();
    container = ProviderContainer(overrides: [
      socialRepositoryProvider.overrideWithValue(repo),
      currentUserIdProvider.overrideWithValue('me'),
    ]);
  });

  tearDown(() => container.dispose());

  void stubSearch(List<UserSummary> results) {
    when(() => repo.searchUsers(any()))
        .thenAnswer((_) async => Right(results));
  }

  final rhea = UserSummary(
    id: 'u1',
    username: 'rhea_menon',
    displayName: 'Rhea Menon',
  );

  group('searching is explicit', () {
    /// Lookups are an exact username match, so every partially typed handle is
    /// a guaranteed miss. Searching as the user types would flash "no match"
    /// through the whole handle and spend a request per keystroke.
    testWidgets('fires no request while typing', (tester) async {
      stubSearch([]);
      await pumpScreen(tester, const SearchUsersScreen(), container: container);

      await tester.enterText(find.byType(TextField), 'rhea');
      await tester.pump(const Duration(seconds: 1));

      verifyNever(() => repo.searchUsers(any()));
    });

    testWidgets('searches when the button is tapped', (tester) async {
      stubSearch([rhea]);
      await pumpScreen(tester, const SearchUsersScreen(), container: container);

      await tester.enterText(find.byType(TextField), 'rhea_menon');
      await tester.pump();
      await tester.tap(find.text('SEARCH'));
      await tester.pumpAndSettle();

      verify(() => repo.searchUsers('rhea_menon')).called(1);
      expect(find.text('Rhea Menon'), findsOneWidget);
      expect(find.text('@rhea_menon'), findsOneWidget);
    });

    testWidgets('searches when the keyboard action is used', (tester) async {
      stubSearch([rhea]);
      await pumpScreen(tester, const SearchUsersScreen(), container: container);

      await tester.enterText(find.byType(TextField), 'rhea_menon');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      verify(() => repo.searchUsers('rhea_menon')).called(1);
    });

    /// Asserted through behaviour rather than the button's `onPressed`:
    /// ElevatedButton.icon builds a private subclass, so a type-based finder
    /// would be testing Flutter's internals rather than ours.
    testWidgets('an empty field searches for nothing', (tester) async {
      stubSearch([]);
      await pumpScreen(tester, const SearchUsersScreen(), container: container);

      await tester.tap(find.text('SEARCH'));
      await tester.pumpAndSettle();

      verifyNever(() => repo.searchUsers(any()));
      expect(find.text('NO MATCH'), findsNothing);
    });

    testWidgets('a whitespace-only query searches for nothing', (tester) async {
      stubSearch([]);
      await pumpScreen(tester, const SearchUsersScreen(), container: container);

      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump();
      await tester.tap(find.text('SEARCH'));
      await tester.pumpAndSettle();

      verifyNever(() => repo.searchUsers(any()));
    });
  });

  group('what the empty state says', () {
    testWidgets('prompts for a username before any search', (tester) async {
      stubSearch([]);
      await pumpScreen(tester, const SearchUsersScreen(), container: container);

      expect(find.text('ADD A FRIEND'), findsOneWidget);
      expect(find.text('NO MATCH'), findsNothing);
    });

    testWidgets('reports no match only after a search has run',
        (tester) async {
      stubSearch([]);
      await pumpScreen(tester, const SearchUsersScreen(), container: container);

      await tester.enterText(find.byType(TextField), 'nobody');
      await tester.pump();
      await tester.tap(find.text('SEARCH'));
      await tester.pumpAndSettle();

      expect(find.text('NO MATCH'), findsOneWidget);
    });

    /// A result — or a failure — belongs to the handle it was searched for.
    /// Leaving "no match" up while the user corrects a typo marks a query they
    /// have already moved on from.
    testWidgets('retracts the no-match message when the text changes',
        (tester) async {
      stubSearch([]);
      await pumpScreen(tester, const SearchUsersScreen(), container: container);

      await tester.enterText(find.byType(TextField), 'nobody');
      await tester.pump();
      await tester.tap(find.text('SEARCH'));
      await tester.pumpAndSettle();
      expect(find.text('NO MATCH'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'nobody_else');
      await tester.pump();

      expect(find.text('NO MATCH'), findsNothing);
      expect(find.text('ADD A FRIEND'), findsOneWidget);
    });
  });
}
