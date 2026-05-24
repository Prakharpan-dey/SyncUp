import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../viewmodels/social_viewmodel.dart';
import '../widgets/user_search_card.dart';

class SearchUsersScreen extends ConsumerStatefulWidget {
  const SearchUsersScreen({super.key});

  @override
  ConsumerState<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends ConsumerState<SearchUsersScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (query.trim().length >= 2) {
        ref.read(socialViewModelProvider.notifier).searchUsers(query);
      } else {
        ref.read(socialViewModelProvider.notifier).clearSearch();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(socialViewModelProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Search Users',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by username or display name...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          ref
                              .read(socialViewModelProvider.notifier)
                              .clearSearch();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              textInputAction: TextInputAction.search,
            ),
          ),

          // Error (offline message)
          if (state.error != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
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

          // Results
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.searchResults.isEmpty
                    ? _buildEmptyState(context, isDark)
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.searchResults.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final user = state.searchResults[index];
                          return UserSearchCard(
                            user: user,
                            onAddFriend: () {
                              ref
                                  .read(socialViewModelProvider.notifier)
                                  .sendFriendRequest(
                                    requesterId: 'current-user',
                                    receiverId: user.id,
                                  );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    final hasSearched = _searchCtrl.text.trim().length >= 2;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasSearched
                  ? Icons.person_search_rounded
                  : Icons.search_rounded,
              size: 48,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              hasSearched
                  ? 'No users found'
                  : 'Search for friends by username\nor display name',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
