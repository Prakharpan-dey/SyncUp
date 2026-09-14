import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neo_brutalism.dart';
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

    // A swipe or clear the server refused puts the card back; say why.
    ref.listen(notificationViewModelProvider.select((s) => s.error),
        (_, error) {
      if (error == null) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error)));
    });

    return Scaffold(
      appBar: AppBar(
        // Opened from Profile, this is pushed and the router supplies the back
        // arrow. A tapped push notification opens it with go() instead, leaving
        // nothing underneath — so offer the way out rather than a dead end.
        leading: context.canPop()
            ? null
            : BackButton(onPressed: () => context.go('/profile')),
        title: const Text('NOTIFICATIONS'),
        actions: [
          // Read means done with it: the list empties rather than keeping
          // every notification dimmed forever.
          if (state.notifications.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                ref.read(notificationViewModelProvider.notifier).clearAll();
              },
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: const Text('READ ALL'),
            ),
        ],
      ),
      body: state.isLoading && state.notifications.isEmpty
          ? const Center(child: CircularProgressIndicator())
          // Pullable either way. The empty page was a plain Column, so it
          // could not be refreshed at all.
          : RefreshIndicator(
              onRefresh: () => ref
                  .read(notificationViewModelProvider.notifier)
                  .loadNotifications(),
              child: state.notifications.isEmpty
              ? LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: _buildEmptyState(context, isDark),
                    ),
                  ),
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: state.notifications.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final notification = state.notifications[index];
                    return NotificationCard(
                      notification: notification,
                      onTap: () {
                        if (!notification.isRead) {
                          ref
                              .read(notificationViewModelProvider.notifier)
                              .markAsRead(notification.id);
                        }
                        if (notification.deepLink != null) {
                          context.go(notification.deepLink!);
                        }
                      },
                      onDismiss: () {
                        ref
                            .read(notificationViewModelProvider.notifier)
                            .dismiss(notification.id);
                      },
                    );
                  },
                ),
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
                color: AppColors.primary,
                isDark: isDark,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'NO NOTIFICATIONS YET',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
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
