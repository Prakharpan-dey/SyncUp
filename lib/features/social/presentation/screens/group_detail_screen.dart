import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/current_user.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neo_brutalism.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../viewmodels/social_viewmodel.dart';
import '../../../../core/widgets/app_snack_bar.dart';

class GroupDetailScreen extends ConsumerStatefulWidget {
  final String groupId;
  const GroupDetailScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(socialViewModelProvider.notifier)
          .loadGroupDetail(widget.groupId);
    });
  }

  void _confirmLeave() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('LEAVE GROUP'),
        content: const Text('Are you sure you want to leave this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(socialViewModelProvider.notifier)
                  .leaveGroup(widget.groupId, ref.read(currentUserIdProvider));
              Navigator.pop(ctx);
              context.go('/feed/groups');
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('LEAVE'),
          ),
        ],
      ),
    );
  }

  void _confirmRemove(String userId, String displayName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('REMOVE MEMBER'),
        content: Text('Remove $displayName from this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(socialViewModelProvider.notifier)
                  .removeMember(widget.groupId, userId);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('REMOVE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(socialViewModelProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final group = state.selectedGroup;
    final currentUserId = ref.watch(currentUserIdProvider);
    // GroupDto maps the API's owner_id onto createdBy.
    final isOwner = group?.createdBy == currentUserId;

    if (state.isLoading && group == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (group == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Group not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(group.name.toUpperCase()),
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.more_vert_rounded),
            itemBuilder: (_) => [
              if (group.inviteToken != null)
                const PopupMenuItem(
                  value: 'copy_invite',
                  child: Row(
                    children: [
                      Icon(Icons.link_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('COPY INVITE LINK'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'leave',
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app_rounded,
                        color: AppColors.error, size: 20),
                    SizedBox(width: 8),
                    Text('LEAVE GROUP',
                        style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'copy_invite' && group.inviteToken != null) {
                Clipboard.setData(
                    ClipboardData(text: group.inviteToken!));
                showAppSnackBar(context, 'Invite link copied!');
              } else if (value == 'leave') {
                _confirmLeave();
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: NeoBrutalism.cardDecoration(isDark: isDark),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: NeoBrutalism.iconBoxDecoration(
                    color: AppColors.accent,
                    isDark: isDark,
                  ),
                  child: const Icon(Icons.groups_rounded,
                      color: Colors.white, size: 32),
                ),
                const SizedBox(height: 12),
                Text(
                  group.name.toUpperCase(),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  '${group.memberCount} member${group.memberCount == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Text(
                'MEMBERS',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
              ),
              const Spacer(),
              Text(
                '${state.groupMembers.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (state.groupMembers.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No members to display',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                ),
              ),
            )
          else
            ...state.groupMembers.map((member) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: NeoBrutalism.flatCardDecoration(isDark: isDark),
                  child: Row(
                    children: [
                      UserAvatar(
                        seed: member.userId,
                        displayName: member.displayName,
                        size: 36,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          member.displayName,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ),
                      if (member.isAdmin)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: NeoBrutalism.chipDecoration(
                            color: AppColors.primary,
                            isDark: isDark,
                          ),
                          child: Text(
                            'ADMIN',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      // Only the owner may remove anyone, and never themselves
                      // — leaving is a separate action with its own succession
                      // rules. The server enforces both regardless.
                      if (isOwner && member.userId != currentUserId)
                        IconButton(
                          icon: const Icon(Icons.person_remove_rounded,
                              size: 20),
                          color: AppColors.error,
                          tooltip: 'Remove from group',
                          onPressed: () => _confirmRemove(
                              member.userId, member.displayName),
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
}
