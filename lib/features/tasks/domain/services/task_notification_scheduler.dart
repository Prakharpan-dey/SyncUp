import 'package:flutter/foundation.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../core/utils/stable_hash.dart';
import '../entities/task.dart';

/// How far ahead reminders are actually scheduled.
///
/// Much shorter than the generation horizon: iOS caps an app at 64 pending
/// local notifications and drops the rest silently, so slots are scarce in a
/// way that database rows are not. A week covers every reminder the user could
/// plausibly need before the app is next opened, and the reconcile tops it up.
const kScheduleHorizonDays = 7;

/// Hard ceiling on scheduled reminders, under the platform limit.
const kMaxScheduled = 60;

/// Keeps the device's pending reminders in step with the task list.
///
/// Deliberately a reconcile rather than incremental bookkeeping: it reads what
/// is actually scheduled and makes the difference. That needs no persisted
/// state and self-heals after a reboot, a reinstall, an exact-alarm permission
/// being granted, or the user flipping the reminders preference — none of which
/// an incremental approach would notice.
class TaskNotificationScheduler {
  final NotificationService _notifications;

  TaskNotificationScheduler(this._notifications);

  /// The reminders [tasks] should currently have, soonest first.
  ///
  /// Pure, so the policy is testable without a plugin.
  static List<Task> desired(
    List<Task> tasks, {
    required bool remindersEnabled,
    DateTime? now,
  }) {
    if (!remindersEnabled) return const [];
    final from = now ?? DateTime.now();
    final horizon = from.add(const Duration(days: kScheduleHorizonDays));

    final wanted = tasks.where((t) {
      if (t.isCompleted) return false;
      // A task with no time of day has nothing to fire at — the server still
      // reminds about those, at day granularity.
      if (t.dueMinutes == null) return false;
      final at = t.dueAt;
      if (at == null) return false;
      return at.isAfter(from) && !at.isAfter(horizon);
    }).toList()
      ..sort((a, b) => a.dueAt!.compareTo(b.dueAt!));

    return wanted.take(kMaxScheduled).toList();
  }

  /// Schedules what is missing and cancels what is no longer wanted.
  Future<void> sync(
    List<Task> tasks, {
    required bool remindersEnabled,
    DateTime? now,
  }) async {
    final wanted = desired(tasks, remindersEnabled: remindersEnabled, now: now);
    final wantedById = {for (final t in wanted) notificationIdFor(t.id): t};

    try {
      final pending = await _notifications.pending();
      final pendingIds = pending.map((p) => p.id).toSet();

      // Cancel first: it frees slots before anything new is scheduled, which
      // matters when the platform cap is close.
      for (final id in pendingIds.difference(wantedById.keys.toSet())) {
        await _notifications.cancel(id);
      }

      for (final entry in wantedById.entries) {
        if (pendingIds.contains(entry.key)) continue;
        final task = entry.value;
        await _notifications.scheduleAt(
          id: entry.key,
          when: task.dueAt!,
          title: task.title,
          body: task.isRecurring ? 'Due now' : 'Task due now',
          payload: '/tasks',
        );
      }
    } catch (e) {
      // Reminders are a convenience; failing to schedule one must never break
      // the action the user actually took.
      debugPrint('TaskNotificationScheduler: sync failed: $e');
    }
  }
}
