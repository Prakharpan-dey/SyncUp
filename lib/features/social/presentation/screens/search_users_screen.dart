import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/current_user.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neo_brutalism.dart';
import '../viewmodels/social_viewmodel.dart';
import '../../domain/entities/user_summary.dart';
import '../../../notifications/di/notification_providers.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../widgets/user_search_card.dart';

class SearchUsersScreen extends ConsumerStatefulWidget {
  const SearchUsersScreen({super.key});

  @override
  ConsumerState<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends ConsumerState<SearchUsersScreen> {
  final _searchCtrl = TextEditingController();

  /// Whether a lookup has been run for the handle currently in the field.
  ///
  /// Lookups are exact, so every partially typed username is a guaranteed
  /// miss. Searching as the user types would flash "no match" through the
  /// whole handle and spend a request per keystroke, so nothing runs until
  /// the user asks for it.
  bool _searched = false;

  /// Username a request was just sent to, so the now-empty results say so
  /// instead of claiming no one has that username.
  String? _requestedName;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onChanged(String _) {
    // A result belongs to the handle it was searched for; once the text moves
    // on, showing it — or a stale "no match" — would be misleading.
    if (_searched) {
      ref.read(socialViewModelProvider.notifier).clearSearch();
    }
    setState(() {
      _searched = false;
      _requestedName = null;
    });
  }

  void _submit() {
    final handle = _searchCtrl.text.trim();
    if (handle.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _searched = true;
      _requestedName = null;
    });
    ref.read(socialViewModelProvider.notifier).searchUsers(handle);
  }

  Future<void> _addFriend(UserSummary user) async {
    final messenger = ScaffoldMessenger.of(context);
    final sent =
        await ref.read(socialViewModelProvider.notifier).sendFriendRequest(
              requesterId: ref.read(currentUserIdProvider),
              receiverId: user.id,
            );
    if (!mounted || !sent) return;
    setState(() => _requestedName = user.username);
    showAppSnackBarOn(messenger, 'Friend request sent to @${user.username}');
    // A friend request is when pushes start to matter, so it is one of the
    // moments notifications are offered.
    await ref
        .read(notificationPermissionHandlerProvider)
        .onFirstMeaningfulAction(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(socialViewModelProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SEARCH USERS',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onChanged,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                // Matched exactly, capitals included — like the server.
                hintText: 'Exact username (capitals matter)',
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

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _searchCtrl.text.trim().isEmpty ? null : _submit,
                icon: const Icon(Icons.search_rounded),
                label: const Text('SEARCH'),
              ),
            ),
          ),

          // Any failure, not just being offline — a server rejection shown under
          // a wifi-off icon reads as a connection problem.
          if (state.error != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: NeoBrutalism.bannerDecoration(
                color: AppColors.warning,
                isDark: isDark,
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
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
                            onAddFriend: () => _addFriend(user),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    final hasSearched = _searched;
    final sentTo = _requestedName;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
              child: Icon(
                sentTo != null
                    ? Icons.mark_email_read_rounded
                    : hasSearched
                        ? Icons.person_search_rounded
                        : Icons.search_rounded,
                size: 36,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              sentTo != null
                  ? 'REQUEST SENT'
                  : hasSearched
                      ? 'NO MATCH'
                      : 'ADD A FRIEND',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              sentTo != null
                  ? '@$sentTo will see it in their friend requests.'
                  : hasSearched
                  ? 'No one has that username.\nCheck the spelling and try again.'
                  : 'Enter a friend’s exact username.\nUsernames are unique.',
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
