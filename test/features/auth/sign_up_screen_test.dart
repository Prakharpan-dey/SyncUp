import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:syncup/core/error/failures.dart';
import 'package:syncup/features/auth/di/auth_providers.dart';
import 'package:syncup/features/auth/domain/repositories/auth_repositories.dart';
import 'package:syncup/features/auth/presentation/screens/sign_up_screen.dart';

import '../../helpers/pump.dart';

class _MockAuthRepo extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepo repo;
  late ProviderContainer container;

  setUp(() {
    repo = _MockAuthRepo();
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
    );
  });

  tearDown(() => container.dispose());

  void stubSignUpFailure(Failure failure) {
    when(() => repo.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          username: any(named: 'username'),
          displayName: any(named: 'displayName'),
        )).thenAnswer((_) async => Left(failure));
  }

  /// Fills every field with values that pass client-side validation, so the
  /// only thing that can fail is the server response under test.
  Future<void> fillValidForm(WidgetTester tester) async {
    await tester.enterText(find.byType(TextFormField).at(0), 'Test Person');
    await tester.enterText(find.byType(TextFormField).at(1), 'freshuser2026');
    await tester.enterText(find.byType(TextFormField).at(2), 'fresh@example.com');
    await tester.enterText(find.byType(TextFormField).at(3), 'PushTest!2026x');
    await tester.pump();
  }

  Future<void> submit(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(ElevatedButton, 'CREATE ACCOUNT'));
    await tester.pumpAndSettle();
  }

  group('server errors land on the field that caused them', () {
    /// All server errors used to collapse into one banner at the bottom of a
    /// four-field form: the user was told something was wrong, but not which
    /// input to fix.
    testWidgets('a duplicate username marks the username field',
        (tester) async {
      stubSignUpFailure(const ServerFailure(
        'Username already taken',
        statusCode: 409,
        fieldErrors: {'username': 'Username already taken'},
      ));

      await pumpScreen(tester, const SignUpScreen(), container: container);
      await fillValidForm(tester);
      await submit(tester);

      expect(find.text('Username already taken'), findsOneWidget);
    });

    testWidgets('a duplicate email marks the email field', (tester) async {
      stubSignUpFailure(const ServerFailure(
        'Email already registered',
        statusCode: 409,
        fieldErrors: {'email': 'Email already registered'},
      ));

      await pumpScreen(tester, const SignUpScreen(), container: container);
      await fillValidForm(tester);
      await submit(tester);

      expect(find.text('Email already registered'), findsOneWidget);
    });

    testWidgets('a 422 can mark several fields at once', (tester) async {
      stubSignUpFailure(const ServerFailure(
        'Validation error',
        statusCode: 422,
        fieldErrors: {
          'username': 'That username is reserved',
          'password': 'Password must be at least 8 characters',
        },
      ));

      await pumpScreen(tester, const SignUpScreen(), container: container);
      await fillValidForm(tester);
      await submit(tester);

      expect(find.text('That username is reserved'), findsOneWidget);
      expect(
        find.text('Password must be at least 8 characters'),
        findsOneWidget,
      );
    });

    /// The same sentence must not appear twice — once under the input and again
    /// in the banner below the form.
    testWidgets('suppresses the banner when a field is marked', (tester) async {
      stubSignUpFailure(const ServerFailure(
        'Username already taken',
        statusCode: 409,
        fieldErrors: {'username': 'Username already taken'},
      ));

      await pumpScreen(tester, const SignUpScreen(), container: container);
      await fillValidForm(tester);
      await submit(tester);

      expect(find.text('Username already taken'), findsOneWidget);
    });

    testWidgets('still shows a banner for an error naming no field',
        (tester) async {
      stubSignUpFailure(const NetworkFailure('No internet connection'));

      await pumpScreen(tester, const SignUpScreen(), container: container);
      await fillValidForm(tester);
      await submit(tester);

      expect(find.text('No internet connection'), findsOneWidget);
    });
  });

  group('errors describe the values that were submitted', () {
    /// Leaving the message up while the user edits marks a field they have
    /// already corrected — the username still read "already taken" after being
    /// replaced with a free one.
    testWidgets('editing a field clears the previous failure', (tester) async {
      stubSignUpFailure(const ServerFailure(
        'Username already taken',
        statusCode: 409,
        fieldErrors: {'username': 'Username already taken'},
      ));

      await pumpScreen(tester, const SignUpScreen(), container: container);
      await fillValidForm(tester);
      await submit(tester);
      expect(find.text('Username already taken'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(1), 'another_name');
      await tester.pump();

      expect(find.text('Username already taken'), findsNothing);
    });

    testWidgets('editing any field clears it, not just the marked one',
        (tester) async {
      stubSignUpFailure(const ServerFailure(
        'Email already registered',
        statusCode: 409,
        fieldErrors: {'email': 'Email already registered'},
      ));

      await pumpScreen(tester, const SignUpScreen(), container: container);
      await fillValidForm(tester);
      await submit(tester);
      expect(find.text('Email already registered'), findsOneWidget);

      // Correcting the display name is still a change to the submission.
      await tester.enterText(find.byType(TextFormField).at(0), 'Someone Else');
      await tester.pump();

      expect(find.text('Email already registered'), findsNothing);
    });
  });

  group('client-side validation runs first', () {
    testWidgets('does not call the server for an invalid email',
        (tester) async {
      stubSignUpFailure(const ServerFailure('unused'));

      await pumpScreen(tester, const SignUpScreen(), container: container);
      await tester.enterText(find.byType(TextFormField).at(0), 'Test Person');
      await tester.enterText(find.byType(TextFormField).at(1), 'freshuser');
      await tester.enterText(find.byType(TextFormField).at(2), 'not-an-email');
      await tester.enterText(find.byType(TextFormField).at(3), 'PushTest!2026x');
      await tester.pump();
      await submit(tester);

      verifyNever(() => repo.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
            username: any(named: 'username'),
            displayName: any(named: 'displayName'),
          ));
    });
  });
}
