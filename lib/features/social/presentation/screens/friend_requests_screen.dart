import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/friendship.dart';
import '../viewmodels/social_viewmodel.dart';

class FriendRequestsScreen extends ConsumerStatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  ConsumerState<FriendRequestsScreen> createState() =>
      _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends ConsumerState<FriendRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    Future.microtask(() {
      final vm = ref.read(socialViewModelProvider.notifier);
      vm.loadPendingRequests('current-user');
      vm.loadFriends('current-user');
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(socialViewModelProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Friends',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: [
            Tab(text: 'Requests (${state.pendingRequests.length})'),
            Tab(text: 'Friends (${state.friends.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          // Pending Requests tab
          state.isLoading && state.pendingRequests.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : state.pendingRequests.isEmpty
                  ? _buildEmptyState(
                      context,
                      isDark,
                      Icons.mail_outline_rounded,
                      'No pending requests',
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
                          onAccept: () => ref
                              .read(socialViewModelProvider.notifier)
                              .respondToRequest(
                                requestId: request.id,
                                response: FriendshipStatus.accepted,
                              ),
                          onReject: () => ref
                              .read(socialViewModelProvider.notifier)
                              .respondToRequest(
                                requestId: request.id,
                                response: FriendshipStatus.rejected,
                              ),
                        );
                      },
                    ),

          // Friends tab
          state.isLoading && state.friends.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : state.friends.isEmpty
                  ? _buildEmptyState(
                      context,
                      isDark,
                      Icons.people_outline_rounded,
                      'No friends yet',
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
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceDark
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.border,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor:
                                    AppColors.accent.withValues(alpha: 0.12),
                                backgroundImage: friend.photoUrl != null
                                    ? NetworkImage(friend.photoUrl!)
                                    : null,
                                child: friend.photoUrl == null
                                    ? Text(
                                        friend.displayName.isNotEmpty
                                            ? friend.displayName[0]
                                                .toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          color: AppColors.accent,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
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
                                              fontWeight: FontWeight.w600),
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
                    ),
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
          Icon(icon, size: 48,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
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
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            backgroundImage: request.requesterPhotoUrl != null
                ? NetworkImage(request.requesterPhotoUrl!)
                : null,
            child: request.requesterPhotoUrl == null
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton.filled(
            onPressed: onAccept,
            icon: const Icon(Icons.check_rounded, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.success.withValues(alpha: 0.12),
              foregroundColor: AppColors.success,
            ),
          ),
          const SizedBox(width: 4),
          IconButton.filled(
            onPressed: onReject,
            icon: const Icon(Icons.close_rounded, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.error.withValues(alpha: 0.12),
              foregroundColor: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}
