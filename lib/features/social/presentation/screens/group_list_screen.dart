import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/current_user.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neo_brutalism.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../domain/entities/group_invite.dart';
import '../viewmodels/social_viewmodel.dart';

class GroupListScreen extends ConsumerStatefulWidget {
  const GroupListScreen({super.key});

  @override
  ConsumerState<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends ConsumerState<GroupListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final vm = ref.read(socialViewModelProvider.notifier);
      vm.loadGroups(ref.read(currentUserIdProvider));
      // A group you are only invited to stays out of the list until you
      // accept; the invite is the one thing you can see of it.
      vm.loadMyInvites();
    });
  }

  void _showCreateGroupDialog() {
    final nameCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('CREATE GROUP'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(
            hintText: 'Group name',
            prefixIcon: Icon(Icons.group_rounded),
          ),
          textCapitalization: TextCapitalization.words,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                ref.read(socialViewModelProvider.notifier).createGroup(
                      name: nameCtrl.text.trim(),
                      createdBy: ref.read(currentUserIdProvider),
                    );
                Navigator.pop(ctx);
              }
            },
            child: const Text('CREATE'),
          ),
        ],
      ),
    );
  }

  /// The invite menu copies a code; this is where it goes. Joining by code
  /// files a request the group's admin approves.
  void _showJoinWithCodeDialog() {
    final codeCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('JOIN WITH CODE'),
        content: TextField(
          controller: codeCtrl,
          decoration: const InputDecoration(
            hintText: 'Invite code',
            prefixIcon: Icon(Icons.key_rounded),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () {
              final code = codeCtrl.text.trim();
              if (code.isEmpty) return;
              Navigator.pop(ctx);
              context.push('/groups/join/${Uri.encodeComponent(code)}');
            },
            child: const Text('JOIN'),
          ),
        ],
      ),
    );
  }

  Future<void> _answerInvite(GroupInvite invite, {required bool accept}) async {
    final messenger = ScaffoldMessenger.of(context);
    final vm = ref.read(socialViewModelProvider.notifier);
    if (accept) {
      final joined = await vm.acceptInvite(invite.id);
      if (!mounted) return;
      showAppSnackBarOn(
        messenger,
        joined
            ? 'You joined ${invite.groupName}'
            : ref.read(socialViewModelProvider).error ?? 'Could not join',
        isError: !joined,
      );
    } else {
      await vm.declineInvite(invite.id);
      if (!mounted) return;
      final error = ref.read(socialViewModelProvider).error;
      showAppSnackBarOn(messenger, error ?? 'Invite declined',
          isError: error != null);
    }
  }

  Widget _buildInvites(BuildContext context, SocialState state, bool isDark) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INVITES (${state.myInvites.length})',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          ...state.myInvites.map((invite) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: NeoBrutalism.cardDecoration(isDark: isDark),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invite.groupName,
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          if (invite.invitedByName != null)
                            Text(
                              'Invited by ${invite.invitedByName}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check_rounded),
                      color: AppColors.success,
                      tooltip: 'Accept',
                      onPressed: () => _answerInvite(invite, accept: true),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      color: AppColors.error,
                      tooltip: 'Decline',
                      onPressed: () => _answerInvite(invite, accept: false),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(socialViewModelProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('GROUPS'),
        actions: [
          TextButton.icon(
            onPressed: _showJoinWithCodeDialog,
            icon: const Icon(Icons.key_rounded, size: 18),
            label: const Text('JOIN WITH CODE'),
          ),
        ],
      ),
      body: Column(
        children: [
          if (state.myInvites.isNotEmpty) _buildInvites(context, state, isDark),
          Expanded(
            child: state.isLoading && state.groups.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.groups.isEmpty
              ? _buildEmptyState(context, isDark)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: state.groups.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final group = state.groups[index];
                    return GestureDetector(
                      onTap: () => context.go('/feed/groups/${group.id}'),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration:
                            NeoBrutalism.cardDecoration(isDark: isDark),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: NeoBrutalism.iconBoxDecoration(
                                color: AppColors.accent,
                                isDark: isDark,
                              ),
                              child: const Icon(
                                Icons.group_rounded,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    group.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                            fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${group.memberCount} member${group.memberCount == 1 ? '' : 's'}',
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
                            Icon(
                              Icons.chevron_right_rounded,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textTertiary,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateGroupDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('NEW GROUP'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
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
                color: AppColors.accent,
                isDark: isDark,
              ),
              child: const Icon(
                Icons.groups_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'NO GROUPS YET',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create or join a group to share\nprogress with your classmates.',
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
