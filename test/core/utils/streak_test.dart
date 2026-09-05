import 'package:flutter_test/flutter_test.dart';
import 'package:syncup/core/utils/streak.dart';
import 'package:syncup/features/tasks/domain/entities/task.dart';

void main() {
  final now = DateTime(2026, 9, 5, 10, 0);
  DateTime daysAgo(int n) => DateTime(2026, 9, 5).subtract(Duration(days: n));

  Task done(DateTime at) => Task(
        id: 't${at.millisecondsSinceEpoch}',
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
        createdAt: now,
        updatedAt: now,
      );

  group('the current streak', () {
    /// The bug this fixes: the walk began at today, so before the first tick of
    /// the day the newest completion failed to match and the streak read 0 — a
    /// forty-day run showed "0 D" all morning.
    test('survives a day that has not been ticked yet', () {
      final tasks = [done(daysAgo(1)), done(daysAgo(2)), done(daysAgo(3))];

      expect(currentStreak(tasks, now: now), 3);
    });

    test('counts today when today is ticked', () {
      final tasks = [done(daysAgo(0)), done(daysAgo(1))];

      expect(currentStreak(tasks, now: now), 2);
    });

    // A day that was genuinely skipped still ends the run.
    test('breaks on a missed day', () {
      final tasks = [done(daysAgo(1)), done(daysAgo(3)), done(daysAgo(4))];

      expect(currentStreak(tasks, now: now), 1);
    });

    test('is zero when the last completion is older than yesterday', () {
      expect(currentStreak([done(daysAgo(2))], now: now), 0);
    });

    test('counts a day once however many tasks were completed on it', () {
      final tasks = [done(daysAgo(1)), done(daysAgo(1)), done(daysAgo(1))];

      expect(currentStreak(tasks, now: now), 1);
    });

    test('ignores tasks that are not completed', () {
      expect(currentStreak([pending()], now: now), 0);
    });

    test('is zero for no tasks at all', () {
      expect(currentStreak(const [], now: now), 0);
    });
  });

  group('the longest streak', () {
    /// The tasks screen passed the current streak for "BEST" too, so the best
    /// figure could never exceed today's run and fell whenever a day was missed.
    test('finds a past run longer than the current one', () {
      final tasks = [
        done(daysAgo(1)), // current run: 1
        done(daysAgo(5)), done(daysAgo(6)), done(daysAgo(7)), done(daysAgo(8)),
      ];

      expect(currentStreak(tasks, now: now), 1);
      expect(longestStreak(tasks), 4);
    });

    test('equals the current run when that is the longest', () {
      final tasks = [done(daysAgo(0)), done(daysAgo(1)), done(daysAgo(2))];

      expect(longestStreak(tasks), 3);
    });

    test('is 1 when no two completed days are adjacent', () {
      final tasks = [done(daysAgo(1)), done(daysAgo(4)), done(daysAgo(9))];

      expect(longestStreak(tasks), 1);
    });

    test('is zero for no completions', () {
      expect(longestStreak(const []), 0);
      expect(longestStreak([pending()]), 0);
    });
  });
}
