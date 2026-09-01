import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:syncup/core/theme/app_theme.dart';
import 'package:syncup/features/auth/domain/entities/user.dart';
import 'package:syncup/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:syncup/features/profile/presentation/screens/privacy_settings_screen.dart';

/// Seeds a signed-in user without touching the interceptor the real
/// [AuthViewModel.build] subscribes to.
class _StubAuthViewModel extends AuthViewModel {
  _StubAuthViewModel(this._seed);
  final User _seed;

  Map<String, dynamic>? lastSent;

  @override
  AuthState build() => AuthState(status: AuthStatus.authenticated, user: _seed);

  @override
  Future<bool> updateProfile(Map<String, dynamic> fields) async {
    lastSent = fields;
    return true;
  }
}

void main() {
  User userWith(String sharing) => User(
        id: 'u1',
        username: 'rhea',
        displayName: 'Rhea',
        email: 'rhea@example.com',
        privacySharingDefault: sharing,
      );

  ProviderContainer containerFor(_StubAuthViewModel vm) => ProviderContainer(
        overrides: [authViewModelProvider.overrideWith(() => vm)],
      );

  /// The screen leaves via `context.go('/profile')` after saving, so it needs a
  /// real router in the tree rather than a bare MaterialApp home.
  Future<void> pumpPrivacy(WidgetTester tester, _StubAuthViewModel vm) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const PrivacySettingsScreen()),
        GoRoute(
          path: '/profile',
          builder: (_, _) => const Scaffold(body: Text('profile')),
        ),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: containerFor(vm),
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
  }

  group('the sharing modes offered', () {
    testWidgets('offers exactly none, summary and all', (tester) async {
      final vm = _StubAuthViewModel(userWith('summary'));
      await pumpPrivacy(tester, vm);

      expect(find.text('Nothing'), findsOneWidget);
      expect(find.text('Summary stats only'), findsOneWidget);
      expect(find.text('All tasks'), findsOneWidget);

      // The option this change removes: it implied per-task granularity that
      // no schema or UI ever backed, and behaved identically to 'All tasks'.
      expect(find.text('Selected tasks'), findsNothing);
    });

    testWidgets('never sends the removed mode to the API', (tester) async {
      final vm = _StubAuthViewModel(userWith('selected'));
      await pumpPrivacy(tester, vm);

      await tester.ensureVisible(find.text('SAVE CHANGES'));
      await tester.tap(find.text('SAVE CHANGES'));
      await tester.pump();
      // The confirmation snackbar schedules its own dismissal, and a pending
      // timer at teardown fails the test independently of the assertion.
      await tester.pump(const Duration(seconds: 5));

      expect(vm.lastSent?['privacy_sharing_default'], 'all');
    });
  });

  group('an account already stored as the removed mode', () {
    /// Otherwise the radio group opens with nothing selected and a save would
    /// silently write back a value the API now rejects.
    testWidgets('falls back to all rather than showing no selection',
        (tester) async {
      final vm = _StubAuthViewModel(userWith('selected'));
      await pumpPrivacy(tester, vm);

      // One check per group: search visibility, and sharing. A sharing group
      // with no selection would leave only one.
      expect(find.byIcon(Icons.check_circle_rounded), findsNWidgets(2));
    });

    testWidgets('leaves a normally stored mode alone', (tester) async {
      final vm = _StubAuthViewModel(userWith('none'));
      await pumpPrivacy(tester, vm);

      await tester.ensureVisible(find.text('SAVE CHANGES'));
      await tester.tap(find.text('SAVE CHANGES'));
      await tester.pump();
      // The confirmation snackbar schedules its own dismissal, and a pending
      // timer at teardown fails the test independently of the assertion.
      await tester.pump(const Duration(seconds: 5));

      expect(vm.lastSent?['privacy_sharing_default'], 'none');
    });
  });
}
