import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/current_user.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neo_brutalism.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../domain/entities/friendship.dart';
import '../../../notifications/di/notification_providers.dart';
import '../viewmodels/social_viewmodel.dart';

class FriendRequestsScreen extends ConsumerStatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  ConsumerState<FriendRequestsScreen> createState() =>
      _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends ConsumerState<FriendRequestsScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() {
      if (!mounted) return;
      _reload();
    });
  }

  /// Reloads both lists. Runs on open, on pull-to-refresh, and when the app
  /// comes back to the foreground: a request that arrived while this screen
  /// sat open used to stay invisible until the screen was rebuilt.
  Future<void> _reload() async {
    final vm = ref.read(socialViewModelProvider.notifier);
    final userId = ref.read(currentUserIdProvider);
    await Future.wait([
      vm.loadPendingRequests(userId),
      vm.loadFriends(userId),
    ]);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) _reload();
  }

  /// Accepting is when a friend's activity — and pushes about it — start to
  /// matter, so it is one of the moments notifications are offered.
  Future<void> _accept(String requestId) async {
    await ref.read(socialViewModelProvider.notifier).respondToRequest(
          requestId: requestId,
          response: FriendshipStatus.accepted,
        );
    if (!mounted) return;
    await ref
        .read(notificationPermissionHandlerProvider)
        .onFirstMeaningfulAction(context);
  }

  /// Pull-to-refresh for one tab. The loading and empty states do not scroll
  /// on their own, so they sit in a view that always does — otherwise
  /// "NO PENDING REQUESTS" could never be pulled to check again.
  Widget _refreshable(Widget child) => RefreshIndicator(
        onRefresh: _reload,
        child: child is ScrollView
            ? child
            : LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(height: constraints.maxHeight, child: child),
                ),
              ),
      );

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(socialViewModelProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'FRIENDS',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: [
            Tab(text: 'REQUESTS (${state.pendingRequests.length})'),
            Tab(text: 'FRIENDS (${state.friends.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          // Pending Requests tab
          _refreshable(state.isLoading && state.pendingRequests.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : state.pendingRequests.isEmpty
                  ? _buildEmptyState(
                      context,
                      isDark,
                      Icons.mail_outline_rounded,
                      'NO PENDING REQUESTS',
                      'Friend requests will appear here.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.pendingRequests.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final request = state.pendingRequests[index];
                        return _RequestCard(
                          request: request,
                          onAccept: () => _accept(request.id),
                          onReject: () => ref
                              .read(socialViewModelProvider.notifier)
                              .respondToRequest(
                                requestId: request.id,
                                response: FriendshipStatus.rejected,
                              ),
                        );
                      },
                    )),

          // Friends tab
          _refreshable(state.isLoading && state.friends.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : state.friends.isEmpty
                  ? _buildEmptyState(
                      context,
                      isDark,
                      Icons.people_outline_rounded,
                      'NO FRIENDS YET',
                      'Search for users to add friends.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.friends.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final friend = state.friends[index];
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: NeoBrutalism.cardDecoration(isDark: isDark),
                          child: Row(
                            children: [
                              UserAvatar(
                                seed: friend.id,
                                displayName: friend.displayName,
                                size: 40,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      friend.displayName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                              fontWeight: FontWeight.w700),
                                    ),
                                    Text(
                                      '@${friend.username}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: isDark
                                                ? AppColors.textSecondaryDark
                                                : AppColors.textSecondary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    )),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark, IconData icon,
      String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: NeoBrutalism.iconBoxDecoration(
              color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
              isDark: isDark,
            ),
            child: Icon(icon, size: 36,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  )),
          const SizedBox(height: 4),
          Text(subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  )),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final Friendship request;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _RequestCard({
    required this.request,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = request.requesterName ?? 'Unknown';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: NeoBrutalism.cardDecoration(isDark: isDark),
      child: Row(
        children: [
          // The requester's own id keys the colour, so they look the same
          // here as they will in the friends list once accepted.
          UserAvatar(seed: request.requesterId, displayName: name, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          // Accept button
          GestureDetector(
            onTap: onAccept,
            child: Container(
              width: 40,
              height: 40,
              decoration: NeoBrutalism.chipDecoration(
                color: AppColors.success,
                isDark: isDark,
              ),
              child: const Icon(Icons.check_rounded,
                  size: 20, color: Colors.black),
            ),
          ),
          const SizedBox(width: 8),
          // Reject button
          GestureDetector(
            onTap: onReject,
            child: Container(
              width: 40,
              height: 40,
              decoration: NeoBrutalism.chipDecoration(
                color: AppColors.error,
                isDark: isDark,
              ),
              child: const Icon(Icons.close_rounded,
                  size: 20, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
