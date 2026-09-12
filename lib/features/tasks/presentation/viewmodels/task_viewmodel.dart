import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/utils/date_helpers.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../di/task_providers.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_series.dart';
import '../../domain/usecases/generate_occurrences_usecase.dart';

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

  /// Tasks completed *today*.
  ///
  /// The home screen's "DONE TODAY" box used [completedCount], which is
  /// all-time — on day 30 of a daily habit it read 30, and it could only ever
  /// go up.
  int get completedTodayCount => tasks
      .where((t) =>
          t.isCompleted &&
          t.completedAt != null &&
          DateHelpers.isToday(t.completedAt!))
      .length;

  /// Tasks due today, whether or not they are done — the honest denominator
  /// for "DONE TODAY".
  int get dueTodayCount =>
      tasks.where((t) => t.dueDate != null && DateHelpers.isToday(t.dueDate!)).length;

  /// The pending tasks worth drawing, with each repeating series collapsed to
  /// the one occurrence it is next due on.
  ///
  /// Generation materializes a fortnight ahead so reminders can be scheduled
  /// offline and the streak has real rows to count — but that is storage, not
  /// a to-do list. Drawing it verbatim meant creating a single daily habit
  /// filled UPCOMING with fourteen identical rows.
  ///
  /// Days already missed are deliberately left alone. They are real work the
  /// user did not do, they already live in their own collapsed section, and
  /// folding them away would put rows beyond the reach of ticking or deleting.
  List<Task> visiblePending({DateTime? now}) {
    final at = now ?? DateTime.now();
    final soonestOfSeries = <String, Task>{};
    final rest = <Task>[];

    for (final task in tasks) {
      if (task.isCompleted) continue;
      final seriesId = task.seriesId;
      final due = task.dueAt;

      if (seriesId == null || (due != null && due.isBefore(at))) {
        rest.add(task);
        continue;
      }

      final incumbent = soonestOfSeries[seriesId];
      if (incumbent == null || _isSooner(due, incumbent.dueAt)) {
        soonestOfSeries[seriesId] = task;
      }
    }

    return [...rest, ...soonestOfSeries.values];
  }
}

/// Nulls sort last: an occurrence always carries a date, but a row without one
/// must not win the comparison by default and hide the dated occurrences.
bool _isSooner(DateTime? candidate, DateTime? incumbent) {
  if (candidate == null) return false;
  if (incumbent == null) return true;
  return candidate.isBefore(incumbent);
}

class TaskViewModel extends Notifier<TaskListState> {
  @override
  TaskListState build() => const TaskListState(isLoading: true);

  /// Whether the user wants task reminders at all.
  ///
  /// Local notifications never reach the server, so they bypass the preference
  /// check the notification worker applies to pushes — the client has to honour
  /// it itself. An absent key means enabled, matching the server's rule, and a
  /// guest (who has no User) is treated the same way.
  bool get _remindersEnabled =>
      ref.read(authViewModelProvider).user?.notificationEnabled('task_reminders') ??
      true;

  /// Brings scheduled reminders back in line with the current task list.
  Future<void> _reconcileReminders() async {
    await ref
        .read(taskNotificationSchedulerProvider)
        .sync(state.tasks, remindersEnabled: _remindersEnabled);
  }

  Future<void> loadTasks(String userId) async {
    state = state.copyWith(isLoading: true, error: null);

    // Materialize any repeating occurrences that have come due before reading,
    // so the list below already contains them. Generation happens here rather
    // than server-side because the app never hydrates tasks from the API.
    try {
      await ref.read(generateOccurrencesUseCaseProvider)(userId);
    } catch (_) {
      // A generation failure must not stop existing tasks from loading.
    }

    final result = await ref.read(getTasksUseCaseProvider).todayTasks(userId);
    result.fold(
      (f) => state = state.copyWith(isLoading: false, error: f.message),
      (tasks) => state = state.copyWith(isLoading: false, tasks: tasks),
    );
    await _reconcileReminders();
  }

  Future<void> submitNewTask({
    required String userId,
    required String title,
    String? description,
    DateTime? dueDate,
    TaskPriority priority = TaskPriority.medium,
    List<String> tags = const [],
    int? dueMinutes,
    String? sharingOverride,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await ref.read(createTaskUseCaseProvider)(
      userId: userId,
      title: title,
      description: description,
      dueDate: dueDate,
      priority: priority,
      tags: tags,
      dueMinutes: dueMinutes,
      sharingOverride: sharingOverride,
    );
    await result.fold(
      (f) async => state = state.copyWith(isLoading: false, error: f.message),
      (task) async {
        state = state.copyWith(isLoading: false, tasks: [task, ...state.tasks]);
        await _reconcileReminders();
      },
    );
  }

  /// Creates a repeating rule and immediately materializes its occurrences.
  Future<bool> submitNewSeries({
    required String userId,
    required String title,
    String? description,
    required Set<int> weekdays,
    int? dueMinutes,
    TaskPriority priority = TaskPriority.medium,
    List<String> tags = const [],
  }) async {
    if (title.trim().isEmpty || weekdays.isEmpty) {
      state = state.copyWith(error: 'Pick at least one day');
      return false;
    }

    final now = DateTime.now();
    final series = TaskSeries(
      id: const Uuid().v4(),
      userId: userId,
      title: title.trim(),
      description: description,
      priority: priority,
      tags: tags,
      weekdays: weekdays,
      dueMinutes: dueMinutes,
      startsOn: dateOnly(now),
      createdAt: now,
      updatedAt: now,
    );

    final result =
        await ref.read(taskSeriesRepositoryProvider).createSeries(series);

    final failure = result.getLeft().toNullable();
    if (failure != null) {
      state = state.copyWith(error: failure.message);
      return false;
    }

    // Materializes the occurrences straight away, so the new habit appears in
    // today's list rather than only after the next app open.
    await loadTasks(userId);
    return true;
  }

  /// Applies a changed rule to the series and to its future occurrences.
  ///
  /// Past and completed occurrences are left exactly as they are, so tick
  /// history and the streak survive an edit.
  ///
  /// Future pending occurrences are **updated in place, keeping their ids**,
  /// never deleted and recreated. Occurrence ids are deterministic, so a
  /// delete-then-create would reuse the same id, and both operations travel
  /// through a fire-and-forget outbox that can interleave them — leaving the
  /// server with the row deleted while the device believes it exists.
  Future<bool> saveSeries(TaskSeries updated) async {
    final result =
        await ref.read(taskSeriesRepositoryProvider).updateSeries(updated);
    final failure = result.getLeft().toNullable();
    if (failure != null) {
      state = state.copyWith(error: failure.message);
      return false;
    }

    final today = dateOnly(DateTime.now());
    final repo = ref.read(taskRepositoryProvider);

    for (final task in state.tasks) {
      if (task.seriesId != updated.id) continue;
      if (task.isCompleted) continue;
      final due = task.dueDate;
      if (due == null || dateOnly(due).isBefore(today)) continue;

      if (updated.repeatsOn(due)) {
        await repo.updateTask(task.copyWith(
          title: updated.title,
          description: updated.description,
          priority: updated.priority,
          dueMinutes: updated.dueMinutes,
        ));
      } else {
        // The rule no longer covers this weekday.
        await repo.deleteTask(task.id);
      }
    }

    // Rewound to just before today, never to null: generation must still not
    // look back past occurrences the user deliberately deleted.
    await ref.read(taskSeriesRepositoryProvider).updateSeries(
          updated.copyWith(
            generatedThrough: today.subtract(const Duration(days: 1)),
          ),
        );

    await loadTasks(updated.userId);
    return true;
  }

  /// Stops a series and removes the occurrences it has not reached yet.
  ///
  /// The series row is kept but deactivated, and completed or past occurrences
  /// stay — deleting them would erase a record of things the user actually did.
  Future<void> stopSeries(TaskSeries series) async {
    final today = dateOnly(DateTime.now());
    final repo = ref.read(taskRepositoryProvider);

    for (final task in state.tasks) {
      if (task.seriesId != series.id || task.isCompleted) continue;
      final due = task.dueDate;
      if (due == null || dateOnly(due).isBefore(today)) continue;
      await repo.deleteTask(task.id);
    }

    await ref
        .read(taskSeriesRepositoryProvider)
        .updateSeries(series.copyWith(active: false));
    await loadTasks(series.userId);
  }

  /// Deletes the rule and every pending day — missed past ones included.
  /// Completed days stay as ordinary tasks, so history and streaks survive.
  ///
  /// Unlike [stopSeries], nothing of the rule is kept. The days are cleared
  /// locally in one pass rather than one outbox DELETE each: the server
  /// removes them itself when the series goes with its pending days.
  Future<void> deleteSeriesPermanently(String seriesId, String userId) async {
    await ref.read(taskRepositoryProvider).removeSeriesLocally(seriesId);
    await ref
        .read(taskSeriesRepositoryProvider)
        .deleteSeries(seriesId, deletePending: true);
    await loadTasks(userId);
  }

  Future<void> toggleCompletion(Task task) async {
    final result = await ref.read(toggleCompletionUseCaseProvider)(task);
    await result.fold(
      (f) async => state = state.copyWith(error: f.message),
      (updatedTask) async {
        final updatedList = state.tasks.map((t) {
          return t.id == updatedTask.id ? updatedTask : t;
        }).toList();
        state = state.copyWith(tasks: updatedList);
        // Completing drops the task out of the desired set, so the reconcile
        // cancels its reminder; un-completing schedules it again if still ahead.
        await _reconcileReminders();
      },
    );
  }

  Future<void> deleteTask(String taskId) async {
    final result = await ref.read(taskRepositoryProvider).deleteTask(taskId);
    await result.fold(
      (f) async => state = state.copyWith(error: f.message),
      (_) async {
        final updatedList = state.tasks.where((t) => t.id != taskId).toList();
        state = state.copyWith(tasks: updatedList);
        await _reconcileReminders();
      },
    );
  }
}

final taskViewModelProvider =
    NotifierProvider<TaskViewModel, TaskListState>(TaskViewModel.new);
