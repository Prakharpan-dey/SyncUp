import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../viewmodels/feed_viewmodel.dart';
import '../widgets/feed_item_card.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        final tab = _tabCtrl.index == 0 ? 'friends' : 'groups';
        ref.read(feedViewModelProvider.notifier).switchTab(tab);
      }
    });

    // Infinite scroll
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(feedViewModelProvider.notifier).loadMore();
      }
    });

    // Load initial feed
    Future.microtask(() {
      ref.read(feedViewModelProvider.notifier).loadFeed();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(feedViewModelProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final vm = ref.read(feedViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Feed',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_search_rounded),
            tooltip: 'Search Users',
            onPressed: () => context.go('/feed/search'),
          ),
          IconButton(
            icon: const Icon(Icons.people_rounded),
            tooltip: 'Friends',
            onPressed: () => context.go('/feed/friends'),
          ),
          IconButton(
            icon: const Icon(Icons.groups_rounded),
            tooltip: 'Groups',
            onPressed: () => context.go('/feed/groups'),
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: 'Friends'),
            Tab(text: 'Groups'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Error / offline banner
          if (state.error != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off_rounded,
                      color: AppColors.warning, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state.error!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ),
            ),

          // Feed content
          Expanded(
            child: state.isLoading && state.items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.items.isEmpty
                    ? _buildEmptyState(context, isDark, state.currentTab)
                    : RefreshIndicator(
                        onRefresh: () =>
                            vm.loadFeed(tab: state.currentTab),
                        child: ListView.separated(
                          controller: _scrollController,
                          padding:
                              const EdgeInsets.fromLTRB(16, 12, 16, 100),
                          itemCount: state.items.length +
                              (state.isLoadingMore ? 1 : 0),
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            // Loading more indicator
                            if (index == state.items.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                    child: CircularProgressIndicator()),
                              );
                            }

                            final item = state.items[index];
                            return FeedItemCard(
                              item: item,
                              onReact: () =>
                                  vm.reactToItem(item.id, '❤️'),
                              onComment: (text) =>
                                  vm.commentOnItem(item.id, text),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
      BuildContext context, bool isDark, String tab) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                tab == 'friends'
                    ? Icons.dynamic_feed_rounded
                    : Icons.groups_rounded,
                size: 48,
                color: AppColors.primary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No activity yet',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              tab == 'friends'
                  ? 'Your feed will show progress\nupdates from your friends.'
                  : 'Group activity will appear here\nonce members start sharing.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/feed/search'),
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Find Friends'),
            ),
          ],
        ),
      ),
    );
  }
}
