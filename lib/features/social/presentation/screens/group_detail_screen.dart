import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/current_user.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neo_brutalism.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../domain/entities/group_invite.dart';
import '../viewmodels/social_viewmodel.dart';
import '../widgets/add_members_sheet.dart';
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

  Future<void> _cancelInvite(SentGroupInvite invite) async {
    final messenger = ScaffoldMessenger.of(context);
    await ref
        .read(socialViewModelProvider.notifier)
        .cancelInvite(widget.groupId, invite.id);
    if (!mounted) return;
    final error = ref.read(socialViewModelProvider).error;
    showAppSnackBarOn(messenger, error ?? 'Invite cancelled',
        isError: error != null);
  }

  /// Approves or rejects one join request and says how it went.
  Future<void> _answerRequest(
    String requestId,
    String displayName, {
    required bool approve,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final vm = ref.read(socialViewModelProvider.notifier);
    if (approve) {
      await vm.approveJoinRequest(widget.groupId, requestId);
    } else {
      await vm.rejectJoinRequest(widget.groupId, requestId);
    }
    if (!mounted) return;
    final error = ref.read(socialViewModelProvider).error;
    showAppSnackBarOn(
      messenger,
      error ?? (approve ? '$displayName joined the group' : 'Request declined'),
      isError: error != null,
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
    // Admins manage membership too; the server enforces the same rule.
    final canManage = isOwner ||
        state.groupMembers.any((m) => m.userId == currentUserId && m.isAdmin);

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
                      Text('COPY INVITE CODE'),
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
                showAppSnackBar(context,
                    'Invite code copied — they enter it under Groups → Join with code');
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

          if (canManage) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => showAddMembersSheet(context, widget.groupId),
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('ADD MEMBERS'),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Invites sent but not yet answered — admins only, like join
          // requests, so for everyone else this is empty.
          if (state.sentInvites.isNotEmpty) ...[
            Text(
              'INVITED (${state.sentInvites.length})',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
            ),
            const SizedBox(height: 12),
            ...state.sentInvites.map((invite) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: NeoBrutalism.flatCardDecoration(isDark: isDark),
                  child: Row(
                    children: [
                      UserAvatar(
                        seed: invite.user.id,
                        displayName: invite.user.displayName,
                        size: 36,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              invite.user.displayName,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              '@${invite.user.username} · waiting to accept',
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
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 22),
                        color: AppColors.error,
                        tooltip: 'Cancel invite',
                        onPressed: () => _cancelInvite(invite),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
          ],

          // Filled only for the owner and admins — nobody else is sent the
          // list — so for everyone else this section simply is not there.
          if (state.joinRequests.isNotEmpty) ...[
            Text(
              'JOIN REQUESTS (${state.joinRequests.length})',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
            ),
            const SizedBox(height: 12),
            ...state.joinRequests.map((request) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: NeoBrutalism.flatCardDecoration(isDark: isDark),
                  child: Row(
                    children: [
                      UserAvatar(
                        seed: request.user.id,
                        displayName: request.user.displayName,
                        size: 36,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              request.user.displayName,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              '@${request.user.username}',
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
                      IconButton(
                        icon: const Icon(Icons.check_rounded, size: 22),
                        color: AppColors.success,
                        tooltip: 'Approve',
                        onPressed: () => _answerRequest(
                          request.id,
                          request.user.displayName,
                          approve: true,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 22),
                        color: AppColors.error,
                        tooltip: 'Reject',
                        onPressed: () => _answerRequest(
                          request.id,
                          request.user.displayName,
                          approve: false,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
          ],

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
