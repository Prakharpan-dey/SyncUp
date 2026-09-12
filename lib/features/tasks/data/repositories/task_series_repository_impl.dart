import 'package:fpdart/fpdart.dart' hide Task, Order;
import 'package:syncup/core/error/failures.dart';
import 'package:syncup/core/storage/models/task_series_ob.dart';
import 'package:syncup/core/storage/object_box_store.dart';
import 'package:syncup/core/sync/connectivity_service.dart';
import 'package:syncup/core/sync/sync_manager.dart';
import 'package:syncup/features/tasks/data/datasources/task_series_remote_datasource.dart';
import 'package:syncup/features/tasks/data/models/task_series_dto.dart';
import 'package:syncup/features/tasks/domain/entities/task.dart';
import 'package:syncup/features/tasks/domain/entities/task_series.dart';
import 'package:syncup/features/tasks/domain/repositories/task_series_repository.dart';
import 'package:syncup/objectbox.g.dart';

/// Local-first, exactly like tasks: ObjectBox is the source of truth the UI
/// reads, and the server is a mirror written through the sync outbox.
class TaskSeriesRepositoryImpl implements TaskSeriesRepository {
  final TaskSeriesRemoteDataSource _remote;
  final ObjectBoxStore _store;
  final SyncManager _syncManager;
  final ConnectivityService _connectivity;

  TaskSeriesRepositoryImpl(
      this._remote, this._store, this._syncManager, this._connectivity);

  Box<TaskSeriesOB> get _box => _store.box<TaskSeriesOB>();

  TaskSeries _obToDomain(TaskSeriesOB ob) => TaskSeries(
        id: ob.id,
        userId: ob.userId,
        title: ob.title,
        description: ob.description,
        priority: TaskPriority.values.byName(ob.priority),
        tags: ob.tags,
        weekdays: parseWeekdays(ob.weekdaysCsv),
        dueMinutes: ob.dueMinutes,
        startsOn: ob.startsOn,
        endsOn: ob.endsOn,
        active: ob.active,
        generatedThrough: ob.generatedThrough,
        createdAt: ob.createdAt,
        updatedAt: ob.updatedAt,
      );

  TaskSeriesOB _domainToOb(TaskSeries s, {bool isSynced = false}) {
    // Preserve the ObjectBox internal id if this series already exists locally.
    final q = _box.query(TaskSeriesOB_.id.equals(s.id)).build();
    final existing = q.findFirst();
    q.close();

    return TaskSeriesOB(
      obId: existing?.obId ?? 0,
      id: s.id,
      userId: s.userId,
      title: s.title,
      description: s.description,
      priority: s.priority.name,
      tags: s.tags,
      weekdaysCsv: formatWeekdays(s.weekdays),
      dueMinutes: s.dueMinutes,
      startsOn: s.startsOn,
      endsOn: s.endsOn,
      active: s.active,
      generatedThrough: s.generatedThrough,
      isSynced: isSynced,
      updatedAt: s.updatedAt,
      createdAt: s.createdAt,
    );
  }

  /// Saves locally first, then mirrors remotely in the background — the same
  /// fire-and-forget shape as tasks, so a series can be created offline.
  void _pushOrEnqueueAsync({
    required String operationType,
    required String entityId,
    required Map<String, dynamic> payload,
    required Future<void> Function() remoteFn,
  }) {
    () async {
      if (await _connectivity.checkConnectivity()) {
        try {
          await remoteFn();
          final q = _box.query(TaskSeriesOB_.id.equals(entityId)).build();
          final local = q.findFirst();
          q.close();
          if (local != null) {
            local.isSynced = true;
            _box.put(local);
          }
          return;
        } catch (_) {
          // fall through to the queue
        }
      }
      await _syncManager.enqueue(
        operationType: operationType,
        entityType: 'task_series',
        entityId: entityId,
        payload: payload,
      );
    }();
  }

  @override
  Future<Either<Failure, List<TaskSeries>>> getSeries(String userId) async {
    try {
      final q = _box.query(TaskSeriesOB_.userId.equals(userId)).build();
      final all = q.find();
      q.close();
      return Right(all.map(_obToDomain).toList());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, TaskSeries>> createSeries(TaskSeries series) async {
    try {
      _box.put(_domainToOb(series));
      final json = TaskSeriesDto.fromDomain(series).toJson();
      _pushOrEnqueueAsync(
        operationType: 'CREATE',
        entityId: series.id,
        payload: json,
        remoteFn: () => _remote.createSeries(json),
      );
      return Right(series);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, TaskSeries>> updateSeries(TaskSeries series) async {
    try {
      final updated = series.copyWith(updatedAt: DateTime.now());
      _box.put(_domainToOb(updated));
      final json = TaskSeriesDto.fromDomain(updated).toJson();
      _pushOrEnqueueAsync(
        operationType: 'UPDATE',
        entityId: series.id,
        payload: json,
        remoteFn: () => _remote.updateSeries(series.id, json),
      );
      return Right(updated);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteSeries(String seriesId,
      {bool deletePending = false}) async {
    try {
      final q = _box.query(TaskSeriesOB_.id.equals(seriesId)).build();
      final local = q.findFirst();
      q.close();
      if (local != null) _box.remove(local.obId);

      _pushOrEnqueueAsync(
        operationType: 'DELETE',
        entityId: seriesId,
        // The flag rides in the payload so a delete queued offline still
        // takes the pending days with it when SyncManager replays it.
        payload: {'id': seriesId, if (deletePending) 'pending': 'delete'},
        remoteFn: () =>
            _remote.deleteSeries(seriesId, deletePending: deletePending),
      );
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
