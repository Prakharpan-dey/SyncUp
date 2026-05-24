import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/sign_in_screen.dart';
import '../../features/auth/presentation/screens/sign_up_screen.dart';
import '../../features/auth/presentation/screens/email_verification_screen.dart';
import '../../features/tasks/presentation/screens/task_list_screen.dart';
import '../../features/tasks/presentation/screens/task_create_screen.dart';
import '../../features/tasks/presentation/screens/task_detail_screen.dart';
import '../../features/attendance/presentation/screens/subject_list_screen.dart';
import '../../features/attendance/presentation/screens/subject_detail_screen.dart';
import '../../features/attendance/presentation/screens/subject_create_screen.dart';
import '../../features/feed/presentation/screens/feed_screen.dart';
import '../../features/social/presentation/screens/search_users_screen.dart';
import '../../features/social/presentation/screens/friend_requests_screen.dart';
import '../../features/social/presentation/screens/group_list_screen.dart';
import '../../features/social/presentation/screens/group_detail_screen.dart';
import '../../features/notifications/presentation/screens/notification_centre_screen.dart';
import '../../features/onboarding/presentation/screens/display_name_screen.dart';
import '../../features/onboarding/presentation/screens/privacy_setup_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/privacy_settings_screen.dart';
import '../../features/profile/presentation/screens/notification_preferences_screen.dart';
import '../../features/profile/presentation/screens/delete_account_screen.dart';
import '../widgets/offline_banner.dart';
import 'route_names.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home', // TODO: change back to '/auth/sign-in' when backend is ready
    routes: [
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
        path: '/auth/verify-email',
        name: RouteNames.verifyEmail,
        builder: (ctx, state) => const EmailVerificationScreen(),
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
            bottomNavigationBar: NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: navigationShell.goBranch,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.check_circle_rounded),
                  label: 'Tasks',
                ),
                NavigationDestination(
                  icon: Icon(Icons.school_rounded),
                  label: 'Attendance',
                ),
                NavigationDestination(
                  icon: Icon(Icons.dynamic_feed_rounded),
                  label: 'Feed',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_rounded),
                  label: 'Profile',
                ),
              ],
            ),
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: RouteNames.home,
                builder: (ctx, state) => const Placeholder(),
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
        path: '/groups/join/:token',
        name: RouteNames.groupJoin,
        builder: (ctx, state) => const Placeholder(),
      ),
    ],
  );
});
