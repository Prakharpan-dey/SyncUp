import 'package:flutter_test/flutter_test.dart';
import 'package:syncup/features/tasks/domain/entities/task.dart';
import 'package:syncup/features/tasks/presentation/viewmodels/task_viewmodel.dart';

void main() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final tomorrow = today.add(const Duration(days: 1));

  Task task({
    required String id,
    DateTime? dueDate,
    DateTime? completedAt,
    String? sharingOverride,
  }) =>
      Task(
        id: id,
        userId: 'u1',
        title: 'Revise DBMS',
        dueDate: dueDate,
        completedAt: completedAt,
        sharingOverride: sharingOverride,
        status: completedAt != null ? TaskStatus.completed : TaskStatus.pending,
        createdAt: today,
        updatedAt: today,
      );

  Set<String> planIds(List<Task> tasks) =>
      TaskListState(tasks: tasks).todaysPlan.map((t) => t.id).toSet();

  group("what today's plan shares", () {
    /// The bug: only tasks dated today counted, so someone whose tasks had no
    /// due date saw a full Home list and never got the share button.
    test('includes unfinished tasks with no due date', () {
      expect(planIds([task(id: 'undated')]), {'undated'});
    });

    test('includes tasks due today and ones already overdue', () {
      expect(
        planIds([
          task(id: 'today', dueDate: today),
          task(id: 'overdue', dueDate: yesterday),
        ]),
        {'today', 'overdue'},
      );
    });

    test('leaves out tasks due later', () {
      expect(planIds([task(id: 'later', dueDate: tomorrow)]), isEmpty);
    });

    test('includes what was finished today, not on earlier days', () {
      expect(
        planIds([
          task(id: 'done-today', completedAt: now),
          task(id: 'done-before', dueDate: yesterday, completedAt: yesterday),
        ]),
        {'done-today'},
      );
    });
  });

  group('what friends see when the plan is shared', () {
    /// The bug: a task marked "Keep this task private" still went out in the
    /// shared plan, because the plan was every task on today's list.
    test('leaves out a private task', () {
      final state = TaskListState(tasks: [
        task(id: 'open'),
        task(id: 'secret', sharingOverride: 'none'),
      ]);

      expect(state.shareablePlan.map((t) => t.id), ['open']);
      expect(state.todaysPlan.map((t) => t.id).toSet(), {'open', 'secret'},
          reason: 'Home still lists it for its owner');
    });
  });

  group('DONE TODAY', () {
    /// The "1/0" bug: finishing an undated task counted as done today, but
    /// the total only counted tasks dated today.
    test("counts out of today's list, so it never reads 1/0", () {
      final state = TaskListState(tasks: [
        task(id: 'undated-done', completedAt: now),
        task(id: 'undated-open'),
      ]);

      expect(state.completedTodayCount, 1);
      expect(state.todaysPlan.length, 2);
    });
  });
}
