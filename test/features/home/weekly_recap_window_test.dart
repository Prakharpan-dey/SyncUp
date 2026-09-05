import 'package:flutter_test/flutter_test.dart';
import 'package:syncup/features/home/presentation/screens/weekly_recap_screen.dart';
import 'package:syncup/features/tasks/domain/entities/task.dart';

void main() {
  // A Monday, so the week runs Mon 7th to Sun 13th.
  final weekStart = DateTime(2026, 9, 7);

  Task completedOn(DateTime at, {String id = 't'}) => Task(
        id: '$id${at.millisecondsSinceEpoch}',
        userId: 'u1',
        title: 'Take medicine',
        status: TaskStatus.completed,
        completedAt: at,
        createdAt: at,
        updatedAt: at,
      );

  Task pending() => Task(
        id: 'p1',
        userId: 'u1',
        title: 'Not done',
        createdAt: weekStart,
        updatedAt: weekStart,
      );

  group('what counts toward the week', () {
    test('keeps a completion inside the week', () {
      final tasks = [completedOn(DateTime(2026, 9, 9, 14, 30))];

      expect(completionsInWeek(tasks, weekStart), hasLength(1));
    });

    /// The bug: every task ever was counted, so the recap's headline and totals
    /// never reset and "you showed up 7 of 7 days" became permanent.
    test('drops a completion from before the week', () {
      final tasks = [completedOn(DateTime(2026, 9, 6, 23, 59))];

      expect(completionsInWeek(tasks, weekStart), isEmpty);
    });

    test('drops a completion from after the week', () {
      final tasks = [completedOn(DateTime(2026, 9, 14))];

      expect(completionsInWeek(tasks, weekStart), isEmpty);
    });

    test('includes the very start of Monday', () {
      expect(completionsInWeek([completedOn(weekStart)], weekStart), hasLength(1));
    });

    test('includes the very end of Sunday', () {
      final tasks = [completedOn(DateTime(2026, 9, 13, 23, 59, 59))];

      expect(completionsInWeek(tasks, weekStart), hasLength(1));
    });

    test('ignores tasks that were never completed', () {
      expect(completionsInWeek([pending()], weekStart), isEmpty);
    });

    test('separates a mixed list correctly', () {
      final tasks = [
        completedOn(DateTime(2026, 9, 1), id: 'old'),
        completedOn(DateTime(2026, 9, 8), id: 'in'),
        completedOn(DateTime(2026, 9, 10), id: 'in'),
        completedOn(DateTime(2026, 9, 20), id: 'later'),
        pending(),
      ];

      expect(completionsInWeek(tasks, weekStart), hasLength(2));
    });

    test('is empty for no tasks', () {
      expect(completionsInWeek(const [], weekStart), isEmpty);
    });
  });
}
