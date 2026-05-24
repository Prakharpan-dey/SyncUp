import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../viewmodels/notification_viewmodel.dart';
import '../widgets/notification_card.dart';

class NotificationCentreScreen extends ConsumerStatefulWidget {
  const NotificationCentreScreen({super.key});

  @override
  ConsumerState<NotificationCentreScreen> createState() =>
      _NotificationCentreScreenState();
}

class _NotificationCentreScreenState
    extends ConsumerState<NotificationCentreScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(notificationViewModelProvider.notifier).loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationViewModelProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (state.unreadCount > 0)
            TextButton.icon(
              onPressed: () {
                ref
                    .read(notificationViewModelProvider.notifier)
                    .markAllAsRead();
              },
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: const Text('Read All'),
            ),
        ],
      ),
      body: state.isLoading && state.notifications.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.notifications.isEmpty
              ? _buildEmptyState(context, isDark)
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.notifications.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final notification = state.notifications[index];
                    return NotificationCard(
                      notification: notification,
                      onTap: () {
                        // Mark as read
                        if (!notification.isRead) {
                          ref
                              .read(notificationViewModelProvider.notifier)
                              .markAsRead(notification.id);
                        }
                        // Navigate to deep link if available
                        if (notification.deepLink != null) {
                          context.go(notification.deepLink!);
                        }
                      },
                      onDismiss: () {
                        ref
                            .read(notificationViewModelProvider.notifier)
                            .markAsRead(notification.id);
                      },
                    );
                  },
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
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 48,
                color: AppColors.primary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No notifications yet',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Task reminders, social updates, and\nattendance warnings will appear here.',
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
