import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/feed_item.dart';

class FeedItemCard extends StatelessWidget {
  final FeedItem item;
  final VoidCallback? onReact;
  final ValueChanged<String>? onComment;

  const FeedItemCard({
    super.key,
    required this.item,
    this.onReact,
    this.onComment,
  });

  IconData get _typeIcon {
    switch (item.type) {
      case FeedItemType.taskCompleted:
        return Icons.check_circle_rounded;
      case FeedItemType.streakMilestone:
        return Icons.local_fire_department_rounded;
      case FeedItemType.attendanceMilestone:
        return Icons.school_rounded;
    }
  }

  Color get _typeColor {
    switch (item.type) {
      case FeedItemType.taskCompleted:
        return AppColors.success;
      case FeedItemType.streakMilestone:
        return AppColors.warning;
      case FeedItemType.attendanceMilestone:
        return AppColors.info;
    }
  }

  String get _timeAgo {
    final diff = DateTime.now().difference(item.createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Actor row
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _typeColor.withValues(alpha: 0.12),
                backgroundImage: item.actorPhotoUrl != null
                    ? NetworkImage(item.actorPhotoUrl!)
                    : null,
                child: item.actorPhotoUrl == null
                    ? Text(
                        item.actorName.isNotEmpty
                            ? item.actorName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: _typeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.actorName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      _timeAgo,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              // Type badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_typeIcon, size: 16, color: _typeColor),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Summary text
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceVariantDark
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(_typeIcon, size: 18, color: _typeColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: item.actorName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(text: ' ${item.summary}'),
                      ],
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Action bar: reactions + comments
          Row(
            children: [
              // Reactions
              _ActionButton(
                icon: Icons.favorite_border_rounded,
                label: item.reactionCount > 0
                    ? '${item.reactionCount}'
                    : 'React',
                onTap: onReact,
              ),
              const SizedBox(width: 16),
              // Comments
              _ActionButton(
                icon: Icons.chat_bubble_outline_rounded,
                label: item.commentCount > 0
                    ? '${item.commentCount}'
                    : 'Comment',
                onTap: () {
                  if (onComment != null) {
                    _showCommentDialog(context);
                  }
                },
              ),
              const Spacer(),
              // Visibility
              Icon(
                item.visibility == FeedVisibility.group
                    ? Icons.group_rounded
                    : Icons.people_rounded,
                size: 14,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textTertiary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCommentDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Comment'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: 'Write a comment...',
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                onComment?.call(ctrl.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
