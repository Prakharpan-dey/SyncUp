import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' hide Task;
import 'package:syncup/core/error/failures.dart';
import 'package:syncup/features/tasks/di/task_providers.dart';
import 'package:syncup/features/tasks/domain/entities/task.dart';
import 'package:syncup/features/tasks/domain/entities/task_series.dart';
import 'package:syncup/features/tasks/domain/repositories/task_repository.dart';
import 'package:syncup/features/tasks/domain/repositories/task_series_repository.dart';
import 'package:syncup/features/tasks/domain/usecases/generate_occurrences_usecase.dart';
import 'package:syncup/features/tasks/presentation/viewmodels/task_viewmodel.dart';

/// Records what the viewmodel asks of it. Only the methods `saveSeries` and
/// `stopSeries` reach are meaningful; the rest satisfy the interface.
class _FakeTaskRepo implements TaskRepository {
  final updated = <Task>[];
  final deleted = <String>[];
  final removedSeries = <String>[];

  @override
  Future<Either<Failure, void>> removeSeriesLocally(String seriesId) async {
    removedSeries.add(seriesId);
    return const Right(null);
  }

  @override
  Future<Either<Failure, Task>> updateTask(Task task) async {
    updated.add(task);
    return Right(task);
  }

  @override
  Future<Either<Failure, void>> deleteTask(String taskId) async {
    deleted.add(taskId);
    return const Right(null);
  }

  @override
  Future<Either<Failure, Task>> createTask(Task task) async => Right(task);

  @override
  Future<Either<Failure, List<Task>>> createOccurrences(List<Task> tasks) async =>
      Right(tasks);

  @override
  Set<String> existingTaskIds(Iterable<String> ids) => ids.toSet();

  @override
  Future<Either<Failure, List<Task>>> getTasksForToday(String userId) async =>
      const Right([]);

  @override
  Future<Either<Failure, List<Task>>> getUpcomingTasks(String userId) async =>
      const Right([]);

  @override
  Future<Either<Failure, Task>> toggleCompletion(Task task) async => Right(task);
}

class _FakeSeriesRepo implements TaskSeriesRepository {
  final saved = <TaskSeries>[];

  @override
  Future<Either<Failure, TaskSeries>> updateSeries(TaskSeries series) async {
    saved.add(series);
    return Right(series);
  }

  @override
  Future<Either<Failure, TaskSeries>> createSeries(TaskSeries series) async =>
      Right(series);

  @override
  Future<Either<Failure, List<TaskSeries>>> getSeries(String userId) async =>
      const Right([]);

  final deletedSeries = <(String, bool)>[];

  @override
  Future<Either<Failure, void>> deleteSeries(String seriesId,
      {bool deletePending = false}) async {
    deletedSeries.add((seriesId, deletePending));
    return const Right(null);
  }
}

/// Seeds the task list and neutralises the reload, which would otherwise pull
/// in generation and the notification plugin.
class _SeededViewModel extends TaskViewModel {
  _SeededViewModel(this._seed);
  final List<Task> _seed;

  @override
  TaskListState build() => TaskListState(tasks: _seed);

  @override
  Future<void> loadTasks(String userId) async {}
}

void main() {
  final today = dateOnly(DateTime.now());

  Task occurrence(
    String id,
    DateTime day, {
    TaskStatus status = TaskStatus.pending,
    String? seriesId = 's1',
  }) =>
      Task(
        id: id,
        userId: 'u1',
        title: 'Take medicine',
        dueDate: day,
        dueMinutes: 9 * 60,
        status: status,
        seriesId: seriesId,
        createdAt: today,
        updatedAt: today,
      );

  TaskSeries series({Set<int>? weekdays, int? dueMinutes}) => TaskSeries(
        id: 's1',
        userId: 'u1',
        title: 'Take medicine',
        weekdays: weekdays ?? {1, 2, 3, 4, 5, 6, 7},
        dueMinutes: dueMinutes ?? 9 * 60,
        startsOn: today,
        createdAt: today,
        updatedAt: today,
      );

  late _FakeTaskRepo tasks;
  late _FakeSeriesRepo seriesRepo;

  ProviderContainer containerWith(List<Task> seed) {
    tasks = _FakeTaskRepo();
    seriesRepo = _FakeSeriesRepo();
    return ProviderContainer(overrides: [
      taskRepositoryProvider.overrideWithValue(tasks),
      taskSeriesRepositoryProvider.overrideWithValue(seriesRepo),
      taskViewModelProvider.overrideWith(() => _SeededViewModel(seed)),
    ]);
  }

  group('editing a series', () {
    /// The trap this pins: occurrence ids are deterministic, so deleting and
    /// recreating would reuse the same id — and both operations travel through
    /// a fire-and-forget outbox that can interleave them, leaving the server
    /// with the row deleted while the device believes it exists.
    test('updates a still-matching future occurrence in place, same id',
        (() async {
      final tomorrow = today.add(const Duration(days: 1));
      final container = containerWith([occurrence('occ-tomorrow', tomorrow)]);
      addTearDown(container.dispose);

      await container
          .read(taskViewModelProvider.notifier)
          .saveSeries(series(dueMinutes: 21 * 60));

      expect(tasks.deleted, isEmpty);
      expect(tasks.updated.single.id, 'occ-tomorrow');
      expect(tasks.updated.single.dueMinutes, 21 * 60);
    }));

    test('removes a future occurrence the rule no longer covers', () async {
      final tomorrow = today.add(const Duration(days: 1));
      final container = containerWith([occurrence('occ-excluded', tomorrow)]);
      addTearDown(container.dispose);

      // Every weekday except tomorrow's, so the occurrence is definitely
      // outside the new rule whatever day the suite runs on.
      final keep = {1, 2, 3, 4, 5, 6, 7}..remove(tomorrow.weekday);

      await container
          .read(taskViewModelProvider.notifier)
          .saveSeries(series(weekdays: keep));

      expect(tasks.deleted, ['occ-excluded']);
      expect(tasks.updated, isEmpty);
    });

    /// Keeping missed days honest is the whole point of the design; an edit
    /// must not quietly rewrite history.
    test('never touches a completed occurrence', () async {
      final yesterday = today.subtract(const Duration(days: 1));
      final container = containerWith([
        occurrence('occ-done', yesterday, status: TaskStatus.completed),
      ]);
      addTearDown(container.dispose);

      await container.read(taskViewModelProvider.notifier).saveSeries(series());

      expect(tasks.updated, isEmpty);
      expect(tasks.deleted, isEmpty);
    });

    test('never touches a past pending occurrence', () async {
      final yesterday = today.subtract(const Duration(days: 1));
      final container = containerWith([occurrence('occ-missed', yesterday)]);
      addTearDown(container.dispose);

      await container.read(taskViewModelProvider.notifier).saveSeries(series());

      expect(tasks.updated, isEmpty);
      expect(tasks.deleted, isEmpty);
    });

    test('leaves occurrences of other series alone', () async {
      final tomorrow = today.add(const Duration(days: 1));
      final container = containerWith(
          [occurrence('other', tomorrow, seriesId: 's2')]);
      addTearDown(container.dispose);

      await container.read(taskViewModelProvider.notifier).saveSeries(series());

      expect(tasks.updated, isEmpty);
      expect(tasks.deleted, isEmpty);
    });

    /// Rewound to yesterday rather than cleared: generation must still refuse
    /// to look back past occurrences the user deliberately deleted.
    test('rewinds the watermark to just before today, never to null', () async {
      final container = containerWith([]);
      addTearDown(container.dispose);

      await container.read(taskViewModelProvider.notifier).saveSeries(series());

      final watermark = seriesRepo.saved.last.generatedThrough;
      expect(watermark, isNotNull);
      expect(watermark, today.subtract(const Duration(days: 1)));
    });
  });

  group('stopping a series', () {
    test('removes future occurrences but keeps what already happened',
        () async {
      final yesterday = today.subtract(const Duration(days: 1));
      final tomorrow = today.add(const Duration(days: 1));
      final container = containerWith([
        occurrence('occ-done', yesterday, status: TaskStatus.completed),
        occurrence('occ-missed', yesterday),
        occurrence('occ-future', tomorrow),
      ]);
      addTearDown(container.dispose);

      await container
          .read(taskViewModelProvider.notifier)
          .stopSeries(series());

      expect(tasks.deleted, ['occ-future']);
    });

    // Deleting the row would orphan completed occurrences that point at it.
    test('deactivates the series rather than deleting it', () async {
      final container = containerWith([]);
      addTearDown(container.dispose);

      await container
          .read(taskViewModelProvider.notifier)
          .stopSeries(series());

      expect(seriesRepo.saved.single.active, isFalse);
    });
  });

  /// Deleting used to remove one day only, and the rule kept generating.
  group('deleting a series permanently', () {
    test('clears the days locally and deletes the rule with its pending days',
        () async {
      final container = containerWith([occurrence('occ-1', today)]);
      addTearDown(container.dispose);

      await container
          .read(taskViewModelProvider.notifier)
          .deleteSeriesPermanently('s1', 'u1');

      expect(tasks.removedSeries, ['s1']);
      expect(seriesRepo.deletedSeries, [('s1', true)]);
      // Not one DELETE per day — the server removes them with the series.
      expect(tasks.deleted, isEmpty);
    });

    /// Completed days are detached, not deleted, so they need a way to lose
    /// the series id.
    test('a task can be detached from its series', () {
      final task = occurrence('occ-2', today, status: TaskStatus.completed);

      expect(task.copyWith(seriesId: null).seriesId, isNull);
      expect(task.copyWith(title: 'Renamed').seriesId, 's1');
    });
  });
}
