import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'route_names.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/auth/sign-in',
    routes: [
      GoRoute(
        path: '/auth/sign-in',
        name: RouteNames.signIn,
        builder: (ctx, state) =>
            const Placeholder(), // replace with SignInScreen
      ),
      GoRoute(
        path: '/auth/sign-up',
        name: RouteNames.signUp,
        builder: (ctx, state) => const Placeholder(),
      ),
      GoRoute(
        path: '/auth/verify-email',
        name: RouteNames.verifyEmail,
        builder: (ctx, state) => const Placeholder(),
      ),
      GoRoute(
        path: '/onboarding',
        name: RouteNames.onboarding,
        builder: (ctx, state) => const Placeholder(),
      ),

      // Main App Shell with bottom nav
      StatefulShellRoute.indexedStack(
        builder: (ctx, state, navigationShell) {
          return Scaffold(
            body: navigationShell,
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
                builder: (ctx, state) => const Placeholder(),
                routes: [
                  GoRoute(
                    path: ':taskId',
                    name: RouteNames.taskDetail,
                    builder: (ctx, state) => const Placeholder(),
                  ),
                  GoRoute(
                    path: 'new',
                    name: RouteNames.taskCreate,
                    builder: (ctx, state) => const Placeholder(),
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
                builder: (ctx, state) => const Placeholder(),
                routes: [
                  GoRoute(
                    path: ':subjectId',
                    name: RouteNames.subjectDetail,
                    builder: (ctx, state) => const Placeholder(),
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
                builder: (ctx, state) => const Placeholder(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: RouteNames.profile,
                builder: (ctx, state) => const Placeholder(),
              ),
            ],
          ),
        ],
      ),

      GoRoute(
        path: '/notifications',
        name: RouteNames.notifications,
        builder: (ctx, state) => const Placeholder(),
      ),
      GoRoute(
        path: '/groups/join/:token',
        name: RouteNames.groupJoin,
        builder: (ctx, state) => const Placeholder(),
      ),
    ],
  );
});
