import 'package:flutter_test/flutter_test.dart';
import 'package:syncup/features/tasks/domain/entities/task.dart';
import 'package:syncup/features/tasks/domain/services/task_notification_scheduler.dart';

void main() {
  final now = DateTime(2026, 9, 7, 8, 0);

  Task task({
    required String id,
    required DateTime day,
    int? minutes,
    TaskStatus status = TaskStatus.pending,
    String? seriesId,
  }) =>
      Task(
        id: id,
        userId: 'u1',
        title: 'Take medicine',
        dueDate: day,
        dueMinutes: minutes,
        status: status,
        seriesId: seriesId,
        createdAt: now,
        updatedAt: now,
      );

  List<Task> desired(List<Task> tasks, {bool enabled = true}) =>
      TaskNotificationScheduler.desired(tasks,
          remindersEnabled: enabled, now: now);

  group('what earns a reminder', () {
    test('a timed task later today does', () {
      final t = task(id: 't1', day: now, minutes: 9 * 60);
      expect(desired([t]), [t]);
    });

    /// The server still reminds about date-only tasks, at day granularity.
    /// Scheduling one here would mean two notifications for the same task.
    test('a task with no time does not', () {
      expect(desired([task(id: 't1', day: now)]), isEmpty);
    });

    test('a completed task does not', () {
      final t = task(
          id: 't1', day: now, minutes: 9 * 60, status: TaskStatus.completed);
      expect(desired([t]), isEmpty);
    });

    /// A notification scheduled in the past fires immediately, which is a
    /// reminder for something already overdue — worse than staying quiet.
    test('a time that has already passed does not', () {
      expect(desired([task(id: 't1', day: now, minutes: 7 * 60)]), isEmpty);
    });

    test('a task beyond the scheduling horizon does not', () {
      final far = now.add(const Duration(days: kScheduleHorizonDays + 1));
      expect(desired([task(id: 't1', day: far, minutes: 9 * 60)]), isEmpty);
    });

    test('a task with no due date at all does not', () {
      final t = Task(
        id: 't1', userId: 'u1', title: 'Someday',
        dueMinutes: 9 * 60, createdAt: now, updatedAt: now,
      );
      expect(desired([t]), isEmpty);
    });
  });

  group('the reminders preference', () {
    /// Local notifications never reach the server, so they bypass the check the
    /// notification worker applies to pushes — the client must honour it.
    test('switching it off wants nothing scheduled', () {
      final t = task(id: 't1', day: now, minutes: 9 * 60);
      expect(desired([t], enabled: false), isEmpty);
    });
  });

  group('the platform cap', () {
    /// iOS silently drops anything past 64 pending notifications, so the ones
    /// that survive must be the soonest rather than an arbitrary slice.
    test('keeps the soonest when there are more than fit', () {
      final many = [
        for (var i = 0; i < kMaxScheduled + 20; i++)
          task(
            id: 't$i',
            day: now.add(Duration(days: i % kScheduleHorizonDays)),
            minutes: 9 * 60 + (i % 60),
          ),
      ];

      final result = desired(many);

      expect(result, hasLength(kMaxScheduled));
      for (var i = 1; i < result.length; i++) {
        expect(result[i].dueAt!.isBefore(result[i - 1].dueAt!), isFalse);
      }
    });

    test('orders by when they are due, soonest first', () {
      final late = task(id: 'late', day: now, minutes: 20 * 60);
      final soon = task(id: 'soon', day: now, minutes: 9 * 60);

      expect(desired([late, soon]).map((t) => t.id), ['soon', 'late']);
    });
  });
}
