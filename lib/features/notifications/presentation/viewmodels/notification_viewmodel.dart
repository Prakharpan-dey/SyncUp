import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/app_notification.dart';
import '../../di/notification_providers.dart';

class NotificationState {
  final List<AppNotification> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? error;

  const NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.error,
  });

  NotificationState copyWith({
    List<AppNotification>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? error,
  }) =>
      NotificationState(
        notifications: notifications ?? this.notifications,
        unreadCount: unreadCount ?? this.unreadCount,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class NotificationViewModel extends Notifier<NotificationState> {
  @override
  NotificationState build() => const NotificationState();

  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true, error: null);
    final result =
        await ref.read(notificationRepositoryProvider).getNotifications();
    result.fold(
      (f) => state = state.copyWith(isLoading: false, error: f.message),
      (notifications) {
        final unread = notifications.where((n) => !n.isRead).length;
        state = state.copyWith(
          isLoading: false,
          notifications: notifications,
          unreadCount: unread,
        );
      },
    );
  }

  Future<void> markAsRead(String id) async {
    final result =
        await ref.read(markNotificationReadUseCaseProvider)(id);
    result.fold(
      (f) => state = state.copyWith(error: f.message),
      (_) {
        final updated = state.notifications.map((n) {
          if (n.id == id) return n.copyWith(isRead: true);
          return n;
        }).toList();
        state = state.copyWith(
          notifications: updated,
          unreadCount: updated.where((n) => !n.isRead).length,
        );
      },
    );
  }

  Future<void> markAllAsRead() async {
    final result =
        await ref.read(notificationRepositoryProvider).markAllAsRead();
    result.fold(
      (f) => state = state.copyWith(error: f.message),
      (_) {
        final updated =
            state.notifications.map((n) => n.copyWith(isRead: true)).toList();
        state = state.copyWith(notifications: updated, unreadCount: 0);
      },
    );
  }
}

final notificationViewModelProvider =
    NotifierProvider<NotificationViewModel, NotificationState>(
        NotificationViewModel.new);
