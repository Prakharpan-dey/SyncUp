import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neo_brutalism.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../social/domain/entities/user_summary.dart';
import '../../../social/presentation/viewmodels/social_viewmodel.dart';

/// Everyone the user has blocked, with a way to undo each.
///
/// Blocking happens from wherever the person appears (a post, the friends
/// list, a group); this is the one place to take it back.
class BlockedUsersScreen extends ConsumerStatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  ConsumerState<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends ConsumerState<BlockedUsersScreen> {
  /// Person currently being unblocked, so only that row shows a spinner.
  String? _unblocking;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() =>
      ref.read(socialViewModelProvider.notifier).loadBlockedUsers();

  Future<void> _unblock(UserSummary user) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _unblocking = user.id);
    final ok =
        await ref.read(socialViewModelProvider.notifier).unblockUser(user.id);
    if (!mounted) return;
    setState(() => _unblocking = null);
    showAppSnackBarOn(
      messenger,
      ok
          ? 'Unblocked ${user.displayName}. Add them again to be friends.'
          : ref.read(socialViewModelProvider).error ?? 'Could not unblock',
      isError: !ok,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(socialViewModelProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    final Widget body;
    if (state.isLoading && state.blockedUsers.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (state.error != null && state.blockedUsers.isEmpty) {
      body = ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          Icon(Icons.cloud_off_rounded, size: 48, color: muted),
          const SizedBox(height: 16),
          Text(state.error!, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(onPressed: _load, child: const Text('RETRY')),
          ),
        ],
      );
    } else if (state.blockedUsers.isEmpty) {
      body = ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          Icon(Icons.block, size: 48, color: muted),
          const SizedBox(height: 16),
          Text('NO ONE BLOCKED',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Block someone from the ⋮ menu on their post, or in your friends '
            'or group lists.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: muted),
          ),
        ],
      );
    } else {
      body = ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: state.blockedUsers.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final user = state.blockedUsers[i];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: NeoBrutalism.flatCardDecoration(isDark: isDark),
            child: Row(
              children: [
                UserAvatar(seed: user.id, displayName: user.displayName, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.displayName,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      Text('@${user.username}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: muted)),
                    ],
                  ),
                ),
                if (_unblocking == user.id)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  OutlinedButton(
                    onPressed: _unblocking != null ? null : () => _unblock(user),
                    child: const Text('UNBLOCK'),
                  ),
              ],
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('BLOCKED USERS')),
      body: SafeArea(child: RefreshIndicator(onRefresh: _load, child: body)),
    );
  }
}
