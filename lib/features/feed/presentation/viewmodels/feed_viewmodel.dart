import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/feed_item.dart';
import '../../di/feed_providers.dart';

class FeedState {
  final List<FeedItem> items;
  final String currentTab; // 'friends' or 'groups'
  final String? cursor;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  const FeedState({
    this.items = const [],
    this.currentTab = 'friends',
    this.cursor,
    this.hasMore = true,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  FeedState copyWith({
    List<FeedItem>? items,
    String? currentTab,
    String? cursor,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
  }) =>
      FeedState(
        items: items ?? this.items,
        currentTab: currentTab ?? this.currentTab,
        cursor: cursor,
        hasMore: hasMore ?? this.hasMore,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        error: error,
      );
}

class FeedViewModel extends Notifier<FeedState> {
  @override
  FeedState build() => const FeedState();

  /// Load first page of the feed
  Future<void> loadFeed({String tab = 'friends'}) async {
    state = state.copyWith(
        isLoading: true, error: null, currentTab: tab, items: []);
    final result = await ref.read(getFeedUseCaseProvider)(tab: tab);
    result.fold(
      (f) => state = state.copyWith(isLoading: false, error: f.message),
      (data) => state = state.copyWith(
        isLoading: false,
        items: data.items,
        cursor: data.nextCursor,
        hasMore: data.nextCursor != null,
      ),
    );
  }

  /// Load next page (infinite scroll).
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore) return;
    state = state.copyWith(isLoadingMore: true, error: null);
    final result = await ref.read(getFeedUseCaseProvider)(
      tab: state.currentTab,
      cursor: state.cursor,
    );
    result.fold(
      (f) => state = state.copyWith(isLoadingMore: false, error: f.message),
      (data) => state = state.copyWith(
        isLoadingMore: false,
        items: [...state.items, ...data.items],
        cursor: data.nextCursor,
        hasMore: data.nextCursor != null,
      ),
    );
  }

  /// Switch tab and reload.
  Future<void> switchTab(String tab) async {
    if (tab == state.currentTab) return;
    await loadFeed(tab: tab);
  }

  /// Toggles this user's reaction on an item.
  ///
  /// The count comes back from the server rather than being incremented here:
  /// reacting is now one-per-user and tapping again removes it, so a local
  /// guess would drift the moment anyone toggled.
  Future<void> reactToItem(String feedItemId, String emoji) async {
    final result = await ref.read(reactToFeedUseCaseProvider)(feedItemId, emoji);
    result.fold(
      (f) => state = state.copyWith(error: f.message),
      (r) {
        final updated = state.items
            .map((item) => item.id == feedItemId
                ? item.copyWith(reactionCount: r.count, reacted: r.reacted)
                : item)
            .toList();
        state = state.copyWith(items: updated);
      },
    );
  }
}

final feedViewModelProvider =
    NotifierProvider<FeedViewModel, FeedState>(FeedViewModel.new);
