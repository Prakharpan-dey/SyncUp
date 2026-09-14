import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/app_notification.dart';
import '../../di/notification_providers.dart';
import 'dart:convert';

import '../../../../core/di/core_providers.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../tasks/domain/services/task_notification_scheduler.dart';
import '../../../tasks/presentation/viewmodels/task_viewmodel.dart';

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

  /// Reminders the phone fired itself are listed as `local:<task id>`.
  static const _kLocalPrefix = 'local:';

  /// Which of those have been read, and which cleared. Kept on the device:
  /// the server never knew about them.
  static const _kLocalReadKey = 'local_reminders_read';
  static const _kLocalDismissedKey = 'local_reminders_dismissed';

  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true, error: null);
    final local = await _localReminders();
    final result =
        await ref.read(notificationRepositoryProvider).getNotifications();
    result.fold(
      // Offline, still show what the device itself knows about.
      (f) => _publish(
        _merge(
          state.notifications
              .where((n) => !n.id.startsWith(_kLocalPrefix))
              .toList(),
          local,
        ),
        error: f.message,
      ),
      (server) => _publish(_merge(server, local)),
    );
  }

  Future<void> markAsRead(String id) async {
    if (id.startsWith(_kLocalPrefix)) {
      await _addIds(_kLocalReadKey, [id]);
      _markRead((n) => n.id == id);
      return;
    }
    final result =
        await ref.read(markNotificationReadUseCaseProvider)(id);
    result.fold(
      (f) => state = state.copyWith(error: f.message),
      (_) => _markRead((n) => n.id == id),
    );
  }

  /// Swiped away: gone for good, here and on the server.
  ///
  /// Swiping used to only mark it read. The card slid off, but the
  /// notification stayed in the list and was back the next time it opened.
  Future<void> dismiss(String id) async {
    final gone = state.notifications.where((n) => n.id == id).firstOrNull;
    if (gone == null) return;
    // Straight away: a swiped card must leave the list the moment it goes.
    _publish(state.notifications.where((n) => n.id != id).toList());

    if (id.startsWith(_kLocalPrefix)) {
      await _addIds(_kLocalDismissedKey, [id]);
      return;
    }
    final result =
        await ref.read(notificationRepositoryProvider).deleteNotification(id);
    // Put it back rather than pretend: it would reappear on the next load.
    result.fold(
      (f) => _publish(_merge([...state.notifications, gone], const []),
          error: f.message),
      (_) {},
    );
  }

  /// READ ALL: empties the list, here and on the server.
  ///
  /// It used to mark everything read and keep it, so the whole list was
  /// still there, dimmed, every time the screen opened.
  Future<void> clearAll() async {
    final all = state.notifications;
    await _addIds(_kLocalDismissedKey, _localIds(all));

    final result = await ref.read(notificationRepositoryProvider).clearAll();
    result.fold(
      (f) => _publish(
        all.where((n) => !n.id.startsWith(_kLocalPrefix)).toList(),
        error: f.message,
      ),
      (_) => _publish(const []),
    );
  }

  /// Task reminders the device showed. Timed tasks are reminded on the phone,
  /// never through the server, so the list — which only held what the server
  /// sent — was missing the notifications the user actually got most often.
  Future<List<AppNotification>> _localReminders() async {
    try {
      final read = await _loadIds(_kLocalReadKey);
      final dismissed = await _loadIds(_kLocalDismissedKey);
      final tasks = ref.read(taskViewModelProvider).tasks;
      final enabled = ref
              .read(authViewModelProvider)
              .user
              ?.notificationEnabled('task_reminders') ??
          true;
      return [
        for (final t in TaskNotificationScheduler.fired(
          tasks,
          remindersEnabled: enabled,
        ))
          if (!dismissed.contains('$_kLocalPrefix${t.id}'))
            AppNotification(
              id: '$_kLocalPrefix${t.id}',
              type: NotificationType.taskReminder,
              title: t.title,
              body: t.isRecurring ? 'Due now' : 'Task due now',
              isRead: read.contains('$_kLocalPrefix${t.id}'),
              deepLink: '/tasks/${t.id}',
              createdAt: t.dueAt!,
            ),
      ];
    } catch (_) {
      // A convenience on top of the server's list; never the reason it fails.
      return const [];
    }
  }

  Iterable<String> _localIds(List<AppNotification> list) =>
      list.where((n) => n.id.startsWith(_kLocalPrefix)).map((n) => n.id);

  List<AppNotification> _merge(
    List<AppNotification> server,
    List<AppNotification> local,
  ) =>
      [...server, ...local]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  void _publish(List<AppNotification> all, {String? error}) {
    state = state.copyWith(
      isLoading: false,
      notifications: all,
      unreadCount: all.where((n) => !n.isRead).length,
      error: error,
    );
  }

  void _markRead(bool Function(AppNotification) which) {
    final updated = state.notifications
        .map((n) => which(n) ? n.copyWith(isRead: true) : n)
        .toList();
    state = state.copyWith(
      notifications: updated,
      unreadCount: updated.where((n) => !n.isRead).length,
    );
  }

  Future<Set<String>> _loadIds(String key) async {
    try {
      final raw = await ref.read(secureStorageProvider).read(key: key);
      if (raw == null || raw.isEmpty) return {};
      return (jsonDecode(raw) as List).cast<String>().toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> _addIds(String key, Iterable<String> ids) async {
    if (ids.isEmpty) return;
    // Bounded: only the last week of reminders is ever listed.
    final kept = {...await _loadIds(key), ...ids}.toList();
    if (kept.length > 200) kept.removeRange(0, kept.length - 200);
    try {
      await ref
          .read(secureStorageProvider)
          .write(key: key, value: jsonEncode(kept));
    } catch (_) {
      // Worst case a reminder shows again.
    }
  }
}

final notificationViewModelProvider =
    NotifierProvider<NotificationViewModel, NotificationState>(
        NotificationViewModel.new);
