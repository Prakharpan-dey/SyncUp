import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/core_providers.dart';
import '../storage/models/subject_ob.dart';
import '../storage/models/task_ob.dart';
import '../storage/models/task_series_ob.dart';
import '../storage/object_box_store.dart';
import '../sync/sync_manager.dart';
import '../utils/date_helpers.dart';
import '../../features/tasks/data/models/task_dto.dart';
import '../../objectbox.g.dart';

/// Re-keys locally-created rows from a guest identity to a real account id.
///
/// Tasks and subjects are stored offline-first, keyed by `userId`, and every
/// read is an exact-match query. Without this step a guest who signs up would
/// watch all of their work disappear: the rows survive, but nothing queries for
/// the old guest id any more.
///
/// Rows are also marked unsynced so the sync queue picks them up and pushes them
/// to the server under the new account.
class GuestDataMigrator {
  final ObjectBoxStore _store;
  final SyncManager _syncManager;

  GuestDataMigrator(this._store, this._syncManager);

  /// Moves every task and subject owned by [guestId] over to [accountId] and
  /// queues them for upload. Returns the number of rows moved. Safe to call when
  /// there is nothing to do.
  Future<int> migrate({
    required String guestId,
    required String accountId,
  }) async {
    if (guestId == accountId || guestId.isEmpty || accountId.isEmpty) return 0;

    final moved =
        // Series first: occurrences carry seriesId, and a server that has not
        // seen the series yet would hold rows pointing at nothing. There is no
        // foreign key, so this is ordering hygiene rather than a hard failure.
        await _rekeyTaskSeries(guestId, accountId) +
            await _rekeyTasks(guestId, accountId) +
            await _rekeySubjects(guestId, accountId);

    if (moved > 0) {
      debugPrint('GuestDataMigrator: moved $moved row(s) to account $accountId');
      // Rows were created with no token, so nothing valid is queued for them.
      unawaited(_syncManager.processQueue());
    }
    return moved;
  }

  Future<int> _rekeyTasks(String guestId, String accountId) async {
    final box = _store.box<TaskOB>();
    final query = box.query(TaskOB_.userId.equals(guestId)).build();
    final rows = query.find();
    query.close();
    if (rows.isEmpty) return 0;

    for (final row in rows) {
      row.userId = accountId;
      row.isSynced = false;
    }
    box.putMany(rows);

    for (final row in rows) {
      // Built through TaskDto rather than by hand: this map used to mirror
      // TaskDto.toJson() by convention and drifted from it, sending nulls the
      // API rejects. One source for the wire shape means it cannot drift again.
      await _syncManager.enqueue(
        operationType: 'CREATE',
        entityType: 'task',
        entityId: row.id,
        payload: TaskDto(
          id: row.id,
          userId: accountId,
          title: row.title,
          description: row.description,
          dueDate: row.dueDate != null
              ? DateHelpers.formatApiDate(row.dueDate!)
              : null,
          priority: row.priority,
          status: row.status,
          tags: row.tags,
          completedAt: row.completedAt?.toIso8601String(),
          seriesId: row.seriesId,
          dueTime: row.dueMinutes != null
              ? DateHelpers.formatApiTime(row.dueMinutes!)
              : null,
        ).toJson(),
      );
    }
    return rows.length;
  }

  /// Moves the guest's repeating rules onto the new account.
  ///
  /// Runs before [_rekeyTasks] so the series reach the server first.
  Future<int> _rekeyTaskSeries(String guestId, String accountId) async {
    final box = _store.box<TaskSeriesOB>();
    final query = box.query(TaskSeriesOB_.userId.equals(guestId)).build();
    final rows = query.find();
    query.close();
    if (rows.isEmpty) return 0;

    for (final row in rows) {
      row.userId = accountId;
      row.isSynced = false;
    }
    box.putMany(rows);

    for (final row in rows) {
      await _syncManager.enqueue(
        operationType: 'CREATE',
        entityType: 'task_series',
        entityId: row.id,
        payload: {
          'id': row.id,
          'title': row.title,
          'priority': row.priority,
          'tags': row.tags,
          'weekdays': row.weekdaysCsv,
          'starts_on': DateHelpers.formatApiDate(row.startsOn),
          'active': row.active,
          if (row.description != null) 'description': row.description,
          if (row.dueMinutes != null)
            'due_time': DateHelpers.formatApiTime(row.dueMinutes!),
          if (row.endsOn != null) 'ends_on': DateHelpers.formatApiDate(row.endsOn!),
          if (row.generatedThrough != null)
            'generated_through': DateHelpers.formatApiDate(row.generatedThrough!),
        },
      );
    }
    return rows.length;
  }

  Future<int> _rekeySubjects(String guestId, String accountId) async {
    final box = _store.box<SubjectOB>();
    final query = box.query(SubjectOB_.userId.equals(guestId)).build();
    final rows = query.find();
    query.close();
    if (rows.isEmpty) return 0;

    for (final row in rows) {
      row.userId = accountId;
      row.isSynced = false;
    }
    box.putMany(rows);

    for (final row in rows) {
      // Payload mirrors SubjectDto.toJson() — keep the two in step.
      await _syncManager.enqueue(
        operationType: 'CREATE',
        entityType: 'subject',
        entityId: row.id,
        payload: {
          'id': row.id,
          'user_id': accountId,
          'name': row.name,
          'code': row.code,
          'threshold_pct': row.thresholdPct,
        },
      );
    }
    return rows.length;
    // Attendance sessions are keyed by subjectId, not userId, so they follow
    // their subject automatically and need no re-keying. They are pushed by
    // whatever queue entries their own writes created.
  }
}

final guestDataMigratorProvider = Provider<GuestDataMigrator>((ref) {
  return GuestDataMigrator(
    ref.watch(objectBoxStoreProvider),
    ref.watch(syncManagerProvider),
  );
});
