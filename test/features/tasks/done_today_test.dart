import 'package:flutter_test/flutter_test.dart';
import 'package:syncup/features/tasks/domain/entities/task.dart';
import 'package:syncup/features/tasks/presentation/viewmodels/task_viewmodel.dart';

void main() {
  final today = DateTime.now();
  final yesterday = today.subtract(const Duration(days: 1));

  Task task({
    required String id,
    DateTime? dueDate,
    DateTime? completedAt,
  }) =>
      Task(
        id: id,
        userId: 'u1',
        title: 'Take medicine',
        dueDate: dueDate,
        completedAt: completedAt,
        status: completedAt != null ? TaskStatus.completed : TaskStatus.pending,
        createdAt: today,
        updatedAt: today,
      );

  group('what "DONE TODAY" counts', () {
    /// The bug: the box used the all-time completed count, so on day 30 of a
    /// daily habit it read 30 and could only ever go up.
    test('ignores completions from previous days', () {
      final state = TaskListState(tasks: [
        task(id: 'a', dueDate: yesterday, completedAt: yesterday),
        task(id: 'b', dueDate: today, completedAt: today),
      ]);

      expect(state.completedTodayCount, 1);
      expect(state.completedCount, 2, reason: 'all-time is still available');
    });

    test('is zero when nothing has been completed today', () {
      final state = TaskListState(tasks: [
        task(id: 'a', dueDate: yesterday, completedAt: yesterday),
        task(id: 'b', dueDate: today),
      ]);

      expect(state.completedTodayCount, 0);
    });

    test('counts a task completed today even if it was due earlier', () {
      final state = TaskListState(tasks: [
        task(id: 'a', dueDate: yesterday, completedAt: today),
      ]);

      expect(state.completedTodayCount, 1);
    });
  });

  group('the denominator', () {
    /// It was every task ever, which made the box read something like "30/44".
    test('counts only tasks due today', () {
      final state = TaskListState(tasks: [
        task(id: 'a', dueDate: today),
        task(id: 'b', dueDate: today, completedAt: today),
        task(id: 'c', dueDate: yesterday),
        task(id: 'd', dueDate: today.add(const Duration(days: 3))),
      ]);

      expect(state.dueTodayCount, 2);
      expect(state.tasks.length, 4, reason: 'all-time is still available');
    });

    test('ignores tasks with no due date', () {
      final state = TaskListState(tasks: [task(id: 'a')]);

      expect(state.dueTodayCount, 0);
    });

    test('is zero for an empty list', () {
      expect(const TaskListState().dueTodayCount, 0);
      expect(const TaskListState().completedTodayCount, 0);
    });
  });
}
