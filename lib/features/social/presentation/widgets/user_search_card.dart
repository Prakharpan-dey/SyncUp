import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neo_brutalism.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../domain/entities/user_summary.dart';

class UserSearchCard extends StatelessWidget {
  final UserSummary user;
  final VoidCallback? onAddFriend;
  final bool requestSent;

  const UserSearchCard({
    super.key,
    required this.user,
    this.onAddFriend,
    this.requestSent = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: NeoBrutalism.flatCardDecoration(isDark: isDark),
      child: Row(
        children: [
          UserAvatar(seed: user.id, displayName: user.displayName, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  '@${user.username}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          if (requestSent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: NeoBrutalism.chipDecoration(
                color: AppColors.success,
                isDark: isDark,
              ),
              child: const Text(
                'SENT',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            )
          else if (onAddFriend != null)
            FilledButton.tonalIcon(
              onPressed: onAddFriend,
              icon: const Icon(Icons.person_add_rounded, size: 18),
              label: const Text('ADD'),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
