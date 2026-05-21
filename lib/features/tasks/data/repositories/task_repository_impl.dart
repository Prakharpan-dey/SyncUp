import 'package:fpdart/fpdart.dart' hide Task, Order;
import 'package:syncup/core/error/failures.dart';
import 'package:syncup/core/storage/models/task_ob.dart';
import 'package:syncup/core/storage/object_box_store.dart';
import 'package:syncup/core/sync/connectivity_service.dart';
import 'package:syncup/core/sync/sync_manager.dart';
import 'package:syncup/features/tasks/data/datasources/task_remote_datasource.dart';
import 'package:syncup/features/tasks/data/models/task_dto.dart';
import 'package:syncup/features/tasks/domain/entities/task.dart';
import 'package:syncup/features/tasks/domain/repositories/task_repository.dart';
import 'package:syncup/objectbox.g.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskRemoteDataSource _remote;
  final ObjectBoxStore _store;
  final SyncManager _syncManager;
  final ConnectivityService _connectivity;

  TaskRepositoryImpl(
      this._remote, this._store, this._syncManager, this._connectivity);

  // helpers

  Box<TaskOB> get _box => _store.box<TaskOB>();

  Task _obToDomain(TaskOB ob) => Task(
        id: ob.id,
        userId: ob.userId,
        title: ob.title,
        description: ob.description,
        dueDate: ob.dueDate,
        priority: TaskPriority.values.byName(ob.priority),
        status: TaskStatus.values.byName(ob.status),
        tags: ob.tags,
        completedAt: ob.completedAt,
        createdAt: ob.createdAt,
        updatedAt: ob.updatedAt,
      );

  TaskOB _domainToOb(Task task, {bool isSynced = false}) {
    // Preserve ObjectBox internal id if the entity already exists locally
    final q = _box.query(TaskOB_.id.equals(task.id)).build();
    final existing = q.findFirst();
    q.close();

    return TaskOB(
      obId: existing?.obId ?? 0,
      id: task.id,
      userId: task.userId,
      title: task.title,
      description: task.description,
      dueDate: task.dueDate,
      priority: task.priority.name,
      status: task.status.name,
      tags: task.tags,
      completedAt: task.completedAt,
      isSynced: isSynced,
      updatedAt: task.updatedAt,
      createdAt: task.createdAt,
    );
  }

  /// Fire-and-forget: saves locally first, then tries remote in background.
  /// Never blocks the caller on network I/O.
  void _pushOrEnqueueAsync({
    required String operationType,
    required String entityId,
    required Map<String, dynamic> payload,
    required Future<void> Function() remoteFn,
  }) {
    // Run async without awaiting — local save already done by caller
    () async {
      if (await _connectivity.checkConnectivity()) {
        try {
          await remoteFn();
          // Mark as synced
          final q = _box.query(TaskOB_.id.equals(entityId)).build();
          final local = q.findFirst();
          q.close();
          if (local != null) {
            local.isSynced = true;
            _box.put(local);
          }
        } catch (_) {
          await _syncManager.enqueue(
            operationType: operationType,
            entityType: 'task',
            entityId: entityId,
            payload: payload,
          );
        }
      } else {
        await _syncManager.enqueue(
          operationType: operationType,
          entityType: 'task',
          entityId: entityId,
          payload: payload,
        );
      }
    }();
  }

  // interface methods 

  @override
  Future<Either<Failure, Task>> createTask(Task task) async {
    try {
      _box.put(_domainToOb(task));
      final json = TaskDto.fromDomain(task).toJson();
      _pushOrEnqueueAsync(
        operationType: 'CREATE',
        entityId: task.id,
        payload: json,
        remoteFn: () => _remote.createTask(json),
      );
      return Right(task);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Task>>> getTasksForToday(String userId) async {
    try {
      // Return ALL tasks for this user (both pending and completed)
      final q = _box
          .query(TaskOB_.userId.equals(userId))
          .order(TaskOB_.createdAt, flags: Order.descending)
          .build();
      final all = q.find();
      q.close();

      return Right(all.map(_obToDomain).toList());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Task>>> getUpcomingTasks(String userId) async {
    try {
      final now = DateTime.now();
      final endOfToday = DateTime(now.year, now.month, now.day + 1);

      final q = _box
          .query(TaskOB_.userId.equals(userId))
          .order(TaskOB_.dueDate)
          .build();
      final all = q.find();
      q.close();

      final upcoming = all.where((t) {
        return t.dueDate != null &&
            t.dueDate!
                .isAfter(endOfToday.subtract(const Duration(seconds: 1)));
      }).toList();

      return Right(upcoming.map(_obToDomain).toList());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Task>> updateTask(Task task) async {
    try {
      final updated = task.copyWith(updatedAt: DateTime.now());
      _box.put(_domainToOb(updated));
      final json = TaskDto.fromDomain(updated).toJson();
      _pushOrEnqueueAsync(
        operationType: 'UPDATE',
        entityId: task.id,
        payload: json,
        remoteFn: () => _remote.updateTask(task.id, json),
      );
      return Right(updated);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Task>> toggleCompletion(Task task) async {
    try {
      final isNowCompleted = task.status == TaskStatus.pending;
      final toggled = task.copyWith(
        status: isNowCompleted ? TaskStatus.completed : TaskStatus.pending,
        completedAt: isNowCompleted ? DateTime.now() : null,
        updatedAt: DateTime.now(),
      );

      _box.put(_domainToOb(toggled));
      final json = TaskDto.fromDomain(toggled).toJson();
      _pushOrEnqueueAsync(
        operationType: 'UPDATE',
        entityId: task.id,
        payload: json,
        remoteFn: () => _remote.updateTask(task.id, json),
      );
      return Right(toggled);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTask(String taskId) async {
    try {
      final q = _box.query(TaskOB_.id.equals(taskId)).build();
      final local = q.findFirst();
      q.close();
      if (local != null) _box.remove(local.obId);

      _pushOrEnqueueAsync(
        operationType: 'DELETE',
        entityId: taskId,
        payload: {'id': taskId},
        remoteFn: () => _remote.deleteTask(taskId),
      );
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}