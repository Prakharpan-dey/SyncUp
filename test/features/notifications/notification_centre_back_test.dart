import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncup/core/theme/app_theme.dart';
import 'package:syncup/core/theme/theme_mode_provider.dart';
import 'package:syncup/features/auth/domain/entities/user.dart';
import 'package:syncup/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:syncup/features/notifications/presentation/screens/notification_centre_screen.dart';
import 'package:syncup/features/notifications/presentation/viewmodels/notification_viewmodel.dart';
import 'package:syncup/features/profile/presentation/screens/profile_screen.dart';

/// Signed in, so Profile shows the bell — it is hidden for guests.
class _StubAuthViewModel extends AuthViewModel {
  @override
  AuthState build() => const AuthState(
        status: AuthStatus.authenticated,
        user: User(
          id: 'u1',
          username: 'rhea',
          displayName: 'Rhea',
          email: 'rhea@example.com',
          privacySharingDefault: 'summary',
        ),
      );
}

/// An empty inbox, without the network the real view model reaches for.
class _StubNotificationViewModel extends NotificationViewModel {
  @override
  NotificationState build() => const NotificationState();

  @override
  Future<void> loadNotifications() async {}
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<void> pumpAt(WidgetTester tester, String location) async {
    final router = GoRouter(
      initialLocation: location,
      routes: [
        GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
        GoRoute(
          path: '/notifications',
          builder: (_, _) => const NotificationCentreScreen(),
        ),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: ProviderContainer(overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          authViewModelProvider.overrideWith(_StubAuthViewModel.new),
          notificationViewModelProvider
              .overrideWith(_StubNotificationViewModel.new),
        ]),
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The bug: Profile opened this screen with go(), which replaced the stack,
  /// so there was no back arrow and nothing to return to.
  testWidgets('opened from Profile, back returns to Profile', (tester) async {
    await pumpAt(tester, '/profile');

    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle();
    expect(find.text('NOTIFICATIONS'), findsOneWidget);
    // Pushed on top of Profile, not swapped in for it. Without this the
    // fallback button below would mask a regression back to go().
    final router =
        GoRouter.of(tester.element(find.byType(NotificationCentreScreen)));
    expect(router.canPop(), isTrue);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('PROFILE'), findsOneWidget);
    expect(find.byType(NotificationCentreScreen), findsNothing);
  });

  /// A tapped push notification opens it with go(), leaving nothing to pop.
  testWidgets('opened with nothing underneath, back still leads to Profile',
      (tester) async {
    await pumpAt(tester, '/notifications');

    expect(find.byType(BackButton), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('PROFILE'), findsOneWidget);
  });
}
