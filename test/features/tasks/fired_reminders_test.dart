import 'package:flutter_test/flutter_test.dart';
import 'package:syncup/features/tasks/domain/entities/task.dart';
import 'package:syncup/features/tasks/domain/services/task_notification_scheduler.dart';

void main() {
  final now = DateTime(2026, 9, 14, 12, 0);
  final today = DateTime(2026, 9, 14);

  Task task(String id, {DateTime? due, int? minutes, DateTime? completedAt}) =>
      Task(
        id: id,
        userId: 'u1',
        title: 'Revise DBMS',
        dueDate: due,
        dueMinutes: minutes,
        completedAt: completedAt,
        status: completedAt != null ? TaskStatus.completed : TaskStatus.pending,
        createdAt: now,
        updatedAt: now,
      );

  List<String> fired(List<Task> tasks, {bool enabled = true}) =>
      TaskNotificationScheduler.fired(tasks, remindersEnabled: enabled, now: now)
          .map((t) => t.id)
          .toList();

  /// The notifications tab only listed what the server sent, and timed tasks
  /// are reminded on the phone — so the reminders the user actually got were
  /// never in it.
  group('reminders the phone already showed', () {
    test('include a timed task whose moment has passed', () {
      expect(fired([task('a', due: today, minutes: 9 * 60)]), ['a']);
    });

    test('leave out one still to come', () {
      expect(fired([task('b', due: today, minutes: 18 * 60)]), isEmpty);
    });

    test('leave out a task with no time — the server sends those itself', () {
      expect(fired([task('c', due: today)]), isEmpty);
    });

    test('leave out one ticked off before its time, which cancelled it', () {
      expect(
        fired([task('d', due: today, minutes: 9 * 60, completedAt: DateTime(2026, 9, 14, 8))]),
        isEmpty,
      );
    });

    test('keep one ticked off after it went off', () {
      expect(
        fired([task('e', due: today, minutes: 9 * 60, completedAt: DateTime(2026, 9, 14, 10))]),
        ['e'],
      );
    });

    test('are empty when reminders are turned off', () {
      expect(fired([task('f', due: today, minutes: 9 * 60)], enabled: false), isEmpty);
    });

    test('go back a week, no further', () {
      expect(fired([task('g', due: DateTime(2026, 9, 6), minutes: 9 * 60)]), isEmpty);
    });

    test('come newest first', () {
      expect(
        fired([
          task('early', due: today, minutes: 8 * 60),
          task('late', due: today, minutes: 11 * 60),
        ]),
        ['late', 'early'],
      );
    });
  });
}
