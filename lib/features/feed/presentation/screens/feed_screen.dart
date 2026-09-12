import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neo_brutalism.dart';
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
        title: Text(
          'FEED',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
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
            Tab(text: 'FRIENDS'),
            Tab(text: 'GROUPS'),
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
              decoration: NeoBrutalism.bannerDecoration(
                color: AppColors.warning,
                isDark: isDark,
              ),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off_rounded,
                      color: Colors.black, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state.error!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
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
                    // Pullable too. It used to be a plain Column, so a feed
                    // that opened empty could never be refreshed and a
                    // friend's new post stayed out of sight.
                    ? RefreshIndicator(
                        onRefresh: () =>
                            vm.loadFeed(tab: state.currentTab),
                        child: LayoutBuilder(
                          builder: (context, constraints) =>
                              SingleChildScrollView(
                            physics:
                                const AlwaysScrollableScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight),
                              child: _buildEmptyState(
                                  context, isDark, state.currentTab),
                            ),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () =>
                            vm.loadFeed(tab: state.currentTab),
                        child: ListView.separated(
                          controller: _scrollController,
                          // A couple of cards do not fill the screen, and a
                          // list that cannot scroll cannot be pulled either.
                          physics: const AlwaysScrollableScrollPhysics(),
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
                              onReact: () => vm.reactToItem(item.id, '❤️'),
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
              decoration: NeoBrutalism.iconBoxDecoration(
                color: AppColors.primaryLight,
                isDark: isDark,
              ),
              child: Icon(
                tab == 'friends'
                    ? Icons.dynamic_feed_rounded
                    : Icons.groups_rounded,
                size: 48,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'NO ACTIVITY YET',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
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
              onPressed: () => context.go(
                  tab == 'friends' ? '/feed/search' : '/feed/groups'),
              icon: Icon(tab == 'friends'
                  ? Icons.person_add_rounded
                  : Icons.groups_rounded),
              label: Text(tab == 'friends' ? 'FIND FRIENDS' : 'YOUR GROUPS'),
            ),
          ],
        ),
      ),
    );
  }
}
