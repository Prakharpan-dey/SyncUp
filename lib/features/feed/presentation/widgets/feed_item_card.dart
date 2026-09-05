import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neo_brutalism.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../domain/entities/feed_item.dart';

class FeedItemCard extends StatelessWidget {
  final FeedItem item;
  final VoidCallback? onReact;

  const FeedItemCard({
    super.key,
    required this.item,
    this.onReact,
  });

  IconData get _typeIcon {
    switch (item.type) {
      case FeedItemType.taskCompleted:
        return Icons.check_circle_rounded;
      case FeedItemType.streakMilestone:
        return Icons.local_fire_department_rounded;
      case FeedItemType.attendanceMilestone:
        return Icons.school_rounded;
      case FeedItemType.dailyPlan:
        return Icons.checklist_rounded;
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
      case FeedItemType.dailyPlan:
        return AppColors.primary;
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
      decoration: NeoBrutalism.cardDecoration(isDark: isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Actor row
          Row(
            children: [
              // Keyed on the actor's id, so the same person is the same colour
              // on every card and for every viewer.
              UserAvatar(
                seed: item.actorId,
                displayName: item.actorName,
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.actorName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      _timeAgo.toUpperCase(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                    ),
                  ],
                ),
              ),
              // Type badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: NeoBrutalism.chipDecoration(
                  color: _typeColor,
                  isDark: isDark,
                ),
                child: Icon(_typeIcon, size: 16, color: Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Summary text
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: NeoBrutalism.flatCardDecoration(
              color: isDark
                  ? AppColors.surfaceVariantDark
                  : AppColors.surfaceVariant,
              isDark: isDark,
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
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(
                          text: item.title.isNotEmpty
                              ? ' ${item.title}'
                              : ' ${item.fallbackSummary}',
                        ),
                      ],
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),

          // A shared plan carries its lines in metadata rather than in the
          // title, so it renders as a checklist instead of a one-line sentence.
          if (item.isPlan) ...[
            const SizedBox(height: 10),
            ...item.planLines.map((line) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        line.done
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 15,
                        color: line.done
                            ? AppColors.success
                            : (isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          line.title,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                decoration: line.done
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: line.done
                                    ? (isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondary)
                                    : null,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )),
            if (item.planHiddenCount > 0)
              Padding(
                padding: const EdgeInsets.only(left: 23, top: 2),
                child: Text(
                  '+${item.planHiddenCount} more',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                ),
              ),
            if (item.summary != null) ...[
              const SizedBox(height: 6),
              Text(
                item.summary!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: AppColors.primary,
                    ),
              ),
            ],
          ],

          const SizedBox(height: 12),

          // Action bar
          Row(
            children: [
              // Reactions
              // Always a count, never the word "REACT": the label swapping
              // between a word and a digit changed the chip's width by ~50px,
              // which was enough to ellipsise the group name on unreacted
              // cards while showing it in full on the rest.
              _ActionChip(
                icon: item.reacted
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                label: '${item.reactionCount}',
                onTap: onReact,
              ),
              const Spacer(),
              // Which group this arrived through, in the corner opposite the
              // react control. Ellipsised rather than wrapped: a long group
              // name should not grow the card.
              if (item.isGroupItem && item.groupName != null)
                Flexible(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: NeoBrutalism.chipDecoration(
                      color: AppColors.accent,
                      isDark: isDark,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.groups_rounded,
                            size: 12, color: Colors.black),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            item.groupName!,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: NeoBrutalism.chipDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          isDark: isDark,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
