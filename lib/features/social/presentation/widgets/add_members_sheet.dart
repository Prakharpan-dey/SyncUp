import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/current_user.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../viewmodels/social_viewmodel.dart';

/// Opens the sheet an owner or admin uses to invite people into [groupId].
Future<void> showAddMembersSheet(BuildContext context, String groupId) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => AddMembersSheet(groupId: groupId),
    );

/// Invite by username or email, or pick from your friends.
///
/// Every route sends an invite the person has to accept — nobody is added to a
/// group they did not agree to be in.
class AddMembersSheet extends ConsumerStatefulWidget {
  final String groupId;

  const AddMembersSheet({super.key, required this.groupId});

  @override
  ConsumerState<AddMembersSheet> createState() => _AddMembersSheetState();
}

class _AddMembersSheetState extends ConsumerState<AddMembersSheet> {
  final _ctrl = TextEditingController();
  final _invitedHere = <String>{};
  bool _sending = false;
  String? _message;
  bool _messageIsError = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      ref
          .read(socialViewModelProvider.notifier)
          .loadFriends(ref.read(currentUserIdProvider));
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _invite({String? typed, String? friendId}) async {
    final value = typed?.trim();
    if (friendId == null && (value == null || value.isEmpty)) return;

    setState(() {
      _sending = true;
      _message = null;
    });
    // An @ means an email; anything else is a username, matched exactly.
    final isEmail = value != null && value.contains('@');
    final result =
        await ref.read(socialViewModelProvider.notifier).inviteToGroup(
              groupId: widget.groupId,
              username: value != null && !isEmail ? value : null,
              email: isEmail ? value : null,
              userId: friendId,
            );
    if (!mounted) return;
    setState(() {
      _sending = false;
      _message = result.message;
      _messageIsError = !result.ok;
      if (result.ok) {
        if (friendId != null) _invitedHere.add(friendId);
        _ctrl.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(socialViewModelProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    final memberIds = state.groupMembers.map((m) => m.userId).toSet();
    final invitedIds = {
      ...state.sentInvites.map((i) => i.user.id),
      ..._invitedHere,
    };
    final friends =
        state.friends.where((f) => !memberIds.contains(f.id)).toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'ADD MEMBERS',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'They get an invite and choose whether to join.',
            style: theme.textTheme.bodySmall?.copyWith(color: secondary),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  enabled: !_sending,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (v) => _invite(typed: v),
                  decoration: const InputDecoration(
                    hintText: 'Username or email',
                    prefixIcon: Icon(Icons.alternate_email_rounded),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _sending ? null : () => _invite(typed: _ctrl.text),
                child: const Text('INVITE'),
              ),
            ],
          ),
          if (_message != null) ...[
            const SizedBox(height: 8),
            Text(
              _message!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: _messageIsError ? AppColors.error : AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 20),
          Text(
            'FRIENDS',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          if (friends.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No friends to add yet — invite by username or email above.',
                style: theme.textTheme.bodySmall?.copyWith(color: secondary),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: ListView(
                shrinkWrap: true,
                children: friends.map((friend) {
                  final invited = invitedIds.contains(friend.id);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: UserAvatar(
                      seed: friend.id,
                      displayName: friend.displayName,
                      size: 36,
                    ),
                    title: Text(friend.displayName),
                    subtitle: Text('@${friend.username}'),
                    trailing: invited
                        ? Text(
                            'INVITED',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: secondary,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : TextButton(
                            onPressed: _sending
                                ? null
                                : () => _invite(friendId: friend.id),
                            child: const Text('INVITE'),
                          ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
