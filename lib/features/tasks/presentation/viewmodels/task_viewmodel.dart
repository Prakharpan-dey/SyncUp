import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/task.dart';
import '../../di/task_providers.dart';

class TaskListState {
  final List<Task> tasks;
  final bool isLoading;
  final String? error;
  const TaskListState(
      {this.tasks = const [], this.isLoading = false, this.error});

  TaskListState copyWith({List<Task>? tasks, bool? isLoading, String? error}) =>
      TaskListState(
        tasks: tasks ?? this.tasks,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );

  int get completedCount => tasks.where((t) => t.isCompleted).length;
  int get pendingCount => tasks.where((t) => !t.isCompleted).length;
}

class TaskViewModel extends Notifier<TaskListState> {
  @override
  TaskListState build() => const TaskListState(isLoading: true);

  Future<void> loadTasks(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await ref.read(getTasksUseCaseProvider).todayTasks(userId);
    result.fold(
      (f) => state = state.copyWith(isLoading: false, error: f.message),
      (tasks) => state = state.copyWith(isLoading: false, tasks: tasks),
    );
  }

  Future<void> submitNewTask({
    required String userId,
    required String title,
    String? description,
    DateTime? dueDate,
    TaskPriority priority = TaskPriority.medium,
    List<String> tags = const [],
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await ref.read(createTaskUseCaseProvider)(
      userId: userId,
      title: title,
      description: description,
      dueDate: dueDate,
      priority: priority,
      tags: tags,
    );
    result.fold(
      (f) => state = state.copyWith(isLoading: false, error: f.message),
      (task) => state =
          state.copyWith(isLoading: false, tasks: [task, ...state.tasks]),
    );
  }

  Future<void> toggleCompletion(Task task) async {
    final result = await ref.read(toggleCompletionUseCaseProvider)(task);
    result.fold(
      (f) => state = state.copyWith(error: f.message),
      (updatedTask) {
        final updatedList = state.tasks.map((t) {
          return t.id == updatedTask.id ? updatedTask : t;
        }).toList();
        state = state.copyWith(tasks: updatedList);
      },
    );
  }

  Future<void> deleteTask(String taskId) async {
    final result =
        await ref.read(taskRepositoryProvider).deleteTask(taskId);
    result.fold(
      (f) => state = state.copyWith(error: f.message),
      (_) {
        final updatedList =
            state.tasks.where((t) => t.id != taskId).toList();
        state = state.copyWith(tasks: updatedList);
      },
    );
  }
}

final taskViewModelProvider =
    NotifierProvider<TaskViewModel, TaskListState>(TaskViewModel.new);