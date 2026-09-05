import 'package:flutter_test/flutter_test.dart';
import 'package:syncup/features/tasks/domain/entities/task.dart';

void main() {
  final stamp = DateTime(2026, 9, 7, 8, 0);

  Task task({DateTime? dueDate, int? minutes, TaskStatus? status}) => Task(
        id: 't1',
        userId: 'u1',
        title: 'Take medicine',
        dueDate: dueDate,
        dueMinutes: minutes,
        status: status ?? TaskStatus.pending,
        createdAt: stamp,
        updatedAt: stamp,
      );

  group('when a task is actually due', () {
    test('a timed task is due at that time', () {
      expect(task(dueDate: DateTime(2026, 9, 7), minutes: 9 * 60).dueAt,
          DateTime(2026, 9, 7, 9));
    });

    /// The bug this fixes: dueDate is stored at midnight, so a date-only task
    /// due today was "overdue" from 00:00 and showed red all day. With no time
    /// given, it is due at the end of its day.
    test('a date-only task is due at the end of its day, not midnight', () {
      expect(task(dueDate: DateTime(2026, 9, 7)).dueAt,
          DateTime(2026, 9, 7, 23, 59));
    });

    test('a task with no date is never due', () {
      expect(task().dueAt, isNull);
    });

    test('a time component on the date does not shift it', () {
      expect(task(dueDate: DateTime(2026, 9, 7, 13, 45), minutes: 9 * 60).dueAt,
          DateTime(2026, 9, 7, 9));
    });
  });

  group('what counts as overdue', () {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final tomorrow = DateTime.now().add(const Duration(days: 1));

    test('a task due today is not overdue before its day ends', () {
      expect(task(dueDate: DateTime.now()).isOverdue, isFalse);
    });

    test('a task due yesterday is overdue', () {
      expect(task(dueDate: yesterday).isOverdue, isTrue);
    });

    test('a task due tomorrow is not', () {
      expect(task(dueDate: tomorrow).isOverdue, isFalse);
    });

    test('a completed task is never overdue', () {
      expect(
        task(dueDate: yesterday, status: TaskStatus.completed).isOverdue,
        isFalse,
      );
    });

    test('a task with no due date is never overdue', () {
      expect(task().isOverdue, isFalse);
    });
  });

  group('clearing fields', () {
    /// The edit screen has to be able to remove a due date or time. copyWith
    /// used `dueDate ?? this.dueDate`, which could only ever set one.
    test('a due date can be cleared', () {
      final t = task(dueDate: DateTime(2026, 9, 7));
      expect(t.copyWith(dueDate: null).dueDate, isNull);
    });

    test('a due time can be cleared', () {
      final t = task(dueDate: DateTime(2026, 9, 7), minutes: 9 * 60);
      expect(t.copyWith(dueMinutes: null).dueMinutes, isNull);
    });

    test('omitting them leaves them alone', () {
      final t = task(dueDate: DateTime(2026, 9, 7), minutes: 9 * 60);
      final same = t.copyWith(title: 'Renamed');

      expect(same.dueDate, DateTime(2026, 9, 7));
      expect(same.dueMinutes, 9 * 60);
    });
  });

  group('equality', () {
    /// props was [id] alone, so an edited task compared equal to its old self
    /// and a ListView could reuse the element and render the stale row.
    test('an edited task differs from its old self', () {
      final before = task(dueDate: DateTime(2026, 9, 7), minutes: 9 * 60);
      expect(before.copyWith(dueMinutes: 21 * 60), isNot(before));
      expect(before.copyWith(title: 'Renamed'), isNot(before));
    });
  });
}
