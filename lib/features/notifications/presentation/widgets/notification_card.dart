import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neo_brutalism.dart';
import '../../domain/entities/app_notification.dart';

class NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const NotificationCard({
    super.key,
    required this.notification,
    this.onTap,
    this.onDismiss,
  });

  IconData get _icon {
    switch (notification.type) {
      case NotificationType.taskReminder:
        return Icons.alarm_rounded;
      case NotificationType.attendanceWarning:
        return Icons.warning_amber_rounded;
      case NotificationType.friendRequest:
        return Icons.person_add_rounded;
      case NotificationType.reaction:
        return Icons.favorite_rounded;
      case NotificationType.comment:
        return Icons.chat_bubble_rounded;
    }
  }

  Color get _iconColor {
    switch (notification.type) {
      case NotificationType.taskReminder:
        return AppColors.primary;
      case NotificationType.attendanceWarning:
        return AppColors.warning;
      case NotificationType.friendRequest:
        return AppColors.accent;
      case NotificationType.reaction:
        return AppColors.error;
      case NotificationType.comment:
        return AppColors.info;
    }
  }

  String get _timeAgo {
    final diff = DateTime.now().difference(notification.createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
            width: NeoBrutalism.borderWidthSmall,
          ),
        ),
        child: const Icon(Icons.done_all_rounded, color: AppColors.success),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: notification.isRead
                ? (isDark ? AppColors.surfaceDark : AppColors.surface)
                : (isDark
                    ? AppColors.primary.withValues(alpha: 0.06)
                    : AppColors.primary.withValues(alpha: 0.04)),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
              width: NeoBrutalism.borderWidthSmall,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: NeoBrutalism.iconBoxDecoration(
                  color: _iconColor,
                  isDark: isDark,
                ),
                child: Icon(_icon, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: notification.isRead
                                ? FontWeight.normal
                                : FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notification.body,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _timeAgo,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textTertiary,
                          ),
                    ),
                  ],
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.border,
                      width: 1,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
