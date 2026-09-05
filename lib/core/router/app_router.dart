import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/screens/weekly_recap_screen.dart';
import '../../features/auth/presentation/screens/sign_in_screen.dart';
import '../../features/auth/presentation/screens/sign_up_screen.dart';
import '../../features/auth/presentation/screens/email_verification_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../features/tasks/presentation/screens/task_list_screen.dart';
import '../../features/tasks/presentation/screens/task_create_screen.dart';
import '../../features/tasks/presentation/screens/task_series_edit_screen.dart';
import '../../features/tasks/presentation/screens/task_detail_screen.dart';
import '../../features/attendance/presentation/screens/subject_list_screen.dart';
import '../../features/attendance/presentation/screens/subject_detail_screen.dart';
import '../../features/attendance/presentation/screens/subject_create_screen.dart';
import '../../features/feed/presentation/screens/feed_screen.dart';
import '../../features/social/presentation/screens/search_users_screen.dart';
import '../../features/social/presentation/screens/friend_requests_screen.dart';
import '../../features/social/presentation/screens/group_list_screen.dart';
import '../../features/social/presentation/screens/group_detail_screen.dart';
import '../../features/social/presentation/screens/group_join_screen.dart';
import '../../features/notifications/presentation/screens/notification_centre_screen.dart';
import '../../features/onboarding/presentation/screens/display_name_screen.dart';
import '../../features/onboarding/presentation/screens/privacy_setup_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/privacy_settings_screen.dart';
import '../../features/profile/presentation/screens/notification_preferences_screen.dart';
import '../../features/profile/presentation/screens/change_password_screen.dart';
import '../../features/profile/presentation/screens/delete_account_screen.dart';
import '../../features/profile/presentation/screens/devices_screen.dart';
import '../theme/app_colors.dart';
import '../theme/neo_brutalism.dart';
import '../widgets/offline_banner.dart';
import 'pending_deep_link.dart';
import 'route_names.dart';
import 'splash_screen.dart';

/// Routes reachable without a session. Reset and verify belong here because the
/// emailed token *is* the credential — the user may open the link on a device
/// where they are not signed in.
const _authPaths = {
  '/auth/sign-in',
  '/auth/sign-up',
  '/auth/forgot-password',
  '/auth/reset-password',
  '/auth/verify-email',
};

/// Routes worth returning to after sign-in, rather than dropping on the floor.
bool _isResumable(String location) => location.startsWith('/groups/join/');

/// Areas that need a real account: everything social plus server-backed profile
/// settings. Guests are sent to sign-in when they land here, with the
/// destination stashed so it resolves once they have an account.
const _accountOnlyPrefixes = [
  '/feed',
  '/groups',
  '/notifications',
  '/onboarding',
  '/profile/privacy',
  '/profile/notification-prefs',
  '/profile/delete-account',
  '/profile/change-password',
  '/profile/devices',
];

bool _requiresAccount(String location) =>
    _accountOnlyPrefixes.any(location.startsWith);

/// The social surface, which additionally needs a verified email address —
/// mirrors the `requireVerifiedEmail` guard on the API.
const _verifiedOnlyPrefixes = ['/feed', '/groups'];

bool _requiresVerifiedEmail(String location) =>
    _verifiedOnlyPrefixes.any(location.startsWith);

final appRouterProvider = Provider<GoRouter>((ref) {
  // Deliberately NOT ref.watch — watching auth here would rebuild this provider
  // on every auth change, handing MaterialApp.router a brand-new GoRouter that
  // resets navigation to initialLocation. Instead the router is built once and
  // told to re-run its redirect via refreshListenable.
  final refresh = ValueNotifier<int>(0);
  final removeListener =
      ref.listen(authViewModelProvider, (_, _) => refresh.value++);
  ref.onDispose(() {
    removeListener.close();
    refresh.dispose();
  });

  return GoRouter(
    // Boots on a neutral splash rather than sign-in. Landing on sign-in would
    // both flash a login form at already-signed-in users and strand guests
    // there, since guests are otherwise allowed to sit on auth routes.
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final authState = ref.read(authViewModelProvider);
      final status = authState.status;
      final isAuthenticated = status == AuthStatus.authenticated;
      final isGuest = status == AuthStatus.guest;
      final location = state.matchedLocation;
      final isOnAuthRoute = _authPaths.contains(location);
      final isOnSplash = location == '/';

      // Session still being restored — hold on the splash.
      if (status == AuthStatus.initial) return isOnSplash ? null : '/';

      // Auth resolved: send the splash on to wherever this user belongs.
      if (isOnSplash) {
        if (isAuthenticated || isGuest) {
          return ref.read(pendingDeepLinkProvider.notifier).consume() ??
              '/home';
        }
        return '/auth/sign-in';
      }

      if (!isAuthenticated && !isGuest && !isOnAuthRoute &&
          !location.startsWith('/onboarding')) {
        // Remember where they were headed so an invite link survives sign-in.
        if (_isResumable(location)) {
          ref.read(pendingDeepLinkProvider.notifier).set(location);
        }
        return '/auth/sign-in';
      }

      // Guests get the local-only surface. Auth routes stay reachable so they
      // can upgrade to a real account whenever they choose.
      if (isGuest) {
        if (isOnAuthRoute) return null;
        if (_requiresAccount(location)) {
          if (_isResumable(location)) {
            ref.read(pendingDeepLinkProvider.notifier).set(location);
          }
          return '/auth/sign-in';
        }
        return null;
      }

      if (isAuthenticated) {
        // Social features need a confirmed address. Send them to the
        // verification screen rather than sign-in — they *are* signed in.
        if (_requiresVerifiedEmail(location) &&
            authState.user?.isEmailVerified != true) {
          return '/auth/verify-email';
        }

        if (isOnAuthRoute) {
          // Let a signed-in but unverified user reach the verify screen; every
          // other auth route means they are done and should go home.
          if (location == '/auth/verify-email' &&
              authState.user?.isEmailVerified != true) {
            return null;
          }
          return ref.read(pendingDeepLinkProvider.notifier).consume() ?? '/home';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (ctx, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth/sign-in',
        name: RouteNames.signIn,
        builder: (ctx, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/auth/sign-up',
        name: RouteNames.signUp,
        builder: (ctx, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        name: RouteNames.forgotPassword,
        builder: (ctx, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/auth/reset-password',
        name: RouteNames.resetPassword,
        // Token arrives in the query string from the emailed link.
        builder: (ctx, state) => ResetPasswordScreen(
          token: state.uri.queryParameters['token'] ?? '',
        ),
      ),
      GoRoute(
        path: '/auth/verify-email',
        name: RouteNames.verifyEmail,
        builder: (ctx, state) => EmailVerificationScreen(
          token: state.uri.queryParameters['token'],
        ),
      ),

      // Onboarding flow
      GoRoute(
        path: '/onboarding',
        name: RouteNames.onboarding,
        builder: (ctx, state) => const DisplayNameScreen(),
        routes: [
          GoRoute(
            path: 'privacy',
            name: RouteNames.privacySetup,
            builder: (ctx, state) => const PrivacySetupScreen(),
          ),
        ],
      ),

      // Main App Shell with bottom nav + offline banner
      StatefulShellRoute.indexedStack(
        builder: (ctx, state, navigationShell) {
          return Scaffold(
            body: Column(
              children: [
                const OfflineBanner(),
                Expanded(child: navigationShell),
              ],
            ),
            // Consumer so the locked state tracks auth without the router
            // itself depending on it.
            bottomNavigationBar: Consumer(
              builder: (context, ref, _) {
                final isGuest = ref.watch(authViewModelProvider).isGuest;
                return _NeoNavBar(
                  currentIndex: navigationShell.currentIndex,
                  onTap: navigationShell.goBranch,
                  // FEED is branch 3 and needs an account.
                  lockedIndices: isGuest ? const {3} : const {},
                );
              },
            ),
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: RouteNames.home,
                builder: (ctx, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tasks',
                name: RouteNames.tasks,
                builder: (ctx, state) => const TaskListScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    name: RouteNames.taskCreate,
                    builder: (ctx, state) => const TaskCreateScreen(),
                  ),
                  // Declared before ':taskId' so the static segment is not
                  // swallowed by the parameterised one.
                  GoRoute(
                    path: 'series/:seriesId/edit',
                    name: RouteNames.taskSeriesEdit,
                    builder: (ctx, state) => TaskSeriesEditScreen(
                      seriesId: state.pathParameters['seriesId']!,
                    ),
                  ),
                  GoRoute(
                    path: ':taskId',
                    name: RouteNames.taskDetail,
                    builder: (ctx, state) => TaskDetailScreen(
                      taskId: state.pathParameters['taskId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/attendance',
                name: RouteNames.attendance,
                builder: (ctx, state) => const SubjectListScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    name: RouteNames.subjectCreate,
                    builder: (ctx, state) => const SubjectCreateScreen(),
                  ),
                  GoRoute(
                    path: ':subjectId',
                    name: RouteNames.subjectDetail,
                    builder: (ctx, state) => SubjectDetailScreen(
                      subjectId: state.pathParameters['subjectId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/feed',
                name: RouteNames.feed,
                builder: (ctx, state) => const FeedScreen(),
                routes: [
                  GoRoute(
                    path: 'search',
                    name: RouteNames.searchUsers,
                    builder: (ctx, state) => const SearchUsersScreen(),
                  ),
                  GoRoute(
                    path: 'friends',
                    name: RouteNames.friendRequests,
                    builder: (ctx, state) => const FriendRequestsScreen(),
                  ),
                  GoRoute(
                    path: 'groups',
                    name: RouteNames.groups,
                    builder: (ctx, state) => const GroupListScreen(),
                    routes: [
                      GoRoute(
                        path: ':groupId',
                        name: RouteNames.groupDetail,
                        builder: (ctx, state) => GroupDetailScreen(
                          groupId: state.pathParameters['groupId']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: RouteNames.profile,
                builder: (ctx, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'privacy',
                    name: RouteNames.privacySettings,
                    builder: (ctx, state) => const PrivacySettingsScreen(),
                  ),
                  GoRoute(
                    path: 'notification-prefs',
                    name: RouteNames.notificationPrefs,
                    builder: (ctx, state) =>
                        const NotificationPreferencesScreen(),
                  ),
                  GoRoute(
                    path: 'change-password',
                    name: RouteNames.changePassword,
                    builder: (ctx, state) => const ChangePasswordScreen(),
                  ),
                  GoRoute(
                    path: 'devices',
                    name: RouteNames.devices,
                    builder: (ctx, state) => const DevicesScreen(),
                  ),
                  GoRoute(
                    path: 'delete-account',
                    name: RouteNames.deleteAccount,
                    builder: (ctx, state) => const DeleteAccountScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      GoRoute(
        path: '/notifications',
        name: RouteNames.notifications,
        builder: (ctx, state) => const NotificationCentreScreen(),
      ),
      GoRoute(
        path: '/weekly-recap',
        name: RouteNames.weeklyRecap,
        builder: (ctx, state) => const WeeklyRecapScreen(),
      ),
      GoRoute(
        path: '/groups/join/:token',
        name: RouteNames.groupJoin,
        builder: (ctx, state) => GroupJoinScreen(
          token: state.pathParameters['token']!,
        ),
      ),
    ],
  );
});

const _navLabels = ['HOME', 'TASKS', 'ATTEND', 'FEED', 'PROFILE'];

class _NeoNavBar extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;

  /// Tabs that need an account. Shown dimmed with a lock rather than hidden, so
  /// guests can see what signing up unlocks.
  final Set<int> lockedIndices;

  const _NeoNavBar({
    required this.currentIndex,
    required this.onTap,
    this.lockedIndices = const {},
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final mutedColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textTertiary;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(
          top: BorderSide(color: borderColor, width: 4),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(_navLabels.length, (i) {
            final isActive = currentIndex == i;
            final isLocked = lockedIndices.contains(i);

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  if (isLocked) {
                    _showLockedMessage(context);
                  } else {
                    onTap(i);
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : surfaceColor,
                    border: i < _navLabels.length - 1
                        ? Border(
                            right: BorderSide(
                              color: borderColor,
                              width: NeoBrutalism.borderWidth,
                            ),
                          )
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isLocked) ...[
                        Icon(Icons.lock_rounded, size: 10, color: mutedColor),
                        const SizedBox(width: 3),
                      ],
                      Text(
                        _navLabels[i],
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isActive
                              ? Colors.white
                              : (isLocked ? mutedColor : textColor),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  void _showLockedMessage(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Create an account to use the feed',
            style: GoogleFonts.archivo(fontWeight: FontWeight.w600),
          ),
          action: SnackBarAction(
            label: 'SIGN UP',
            onPressed: () => context.go('/auth/sign-up'),
          ),
        ),
      );
  }
}
