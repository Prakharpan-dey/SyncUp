import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:syncup/objectbox.g.dart';

import '../storage/models/sync_queue_item_ob.dart';
import '../storage/object_box_store.dart';
import '../constants/app_constants.dart';
import 'connectivity_service.dart';

/// Drains locally-queued writes to the server once connectivity returns.
///
/// Offline-first repositories write to ObjectBox first and enqueue here when the
/// immediate push fails or the device is offline. Items are replayed in creation
/// order so a create always precedes the update that follows it.
class SyncManager {
  final ObjectBoxStore _store;
  final ConnectivityService _connectivity;
  final Dio _dio;
  final FlutterSecureStorage _storage;

  bool _isProcessing = false; // mutex
  StreamSubscription? _sub;

  SyncManager(this._store, this._connectivity, this._dio, this._storage) {
    _sub = _connectivity.onConnectivityChanged.listen((online) {
      if (online) processQueue();
    });
  }

  Future<void> enqueue({
    required String operationType,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> payload,
  }) async {
    _store.box<SyncQueueItemOB>().put(
          SyncQueueItemOB(
            operationType: operationType,
            entityType: entityType,
            entityId: entityId,
            payloadJson: jsonEncode(payload),
          ),
        );
  }

  Future<void> processQueue() async {
    if (_isProcessing || !_connectivity.isOnline) return;

    // Guest sessions have no token. Draining now would 401 every item and burn
    // through the retry budget, so hold the queue until they sign in — at which
    // point the rows have been re-keyed to the new account and can sync.
    final token = await _storage.read(key: 'access_token');
    if (token == null) return;

    _isProcessing = true;
    try {
      final box = _store.box<SyncQueueItemOB>();
      final query = box
          .query(SyncQueueItemOB_.status.equals('pending'))
          .order(SyncQueueItemOB_.createdAt)
          .build();
      final pending = query.find();
      query.close();

      for (var i = 0; i < pending.length; i += AppConstants.syncBatchSize) {
        final batch = pending.skip(i).take(AppConstants.syncBatchSize);
        for (final item in batch) {
          await _processItem(item, box);
        }
        if (i + AppConstants.syncBatchSize < pending.length) {
          await Future.delayed(AppConstants.syncMinDelay);
        }
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _processItem(
    SyncQueueItemOB item,
    Box<SyncQueueItemOB> box,
  ) async {
    item.status = 'in_flight';
    box.put(item);

    try {
      await _send(item);
      box.remove(item.obId);
    } on DioException catch (e) {
      if (_isPermanent(e)) {
        // Retrying will never help (bad payload, deleted resource, forbidden).
        // Park it as failed rather than looping.
        debugPrint(
          'SyncManager: dropping ${item.operationType} ${item.entityType} '
          '${item.entityId} — ${e.response?.statusCode} ${e.message}',
        );
        item.status = 'failed';
        box.put(item);
        return;
      }
      await _scheduleRetry(item, box);
    } catch (e) {
      debugPrint('SyncManager: unexpected error for ${item.entityId}: $e');
      await _scheduleRetry(item, box);
    }
  }

  Future<void> _scheduleRetry(
    SyncQueueItemOB item,
    Box<SyncQueueItemOB> box,
  ) async {
    item.retryCount++;
    item.status =
        item.retryCount >= AppConstants.syncMaxRetries ? 'failed' : 'pending';
    box.put(item);

    if (item.status == 'pending') {
      await Future.delayed(Duration(seconds: pow(2, item.retryCount).toInt()));
    }
  }

  /// Dispatches one queued operation to its endpoint.
  Future<void> _send(SyncQueueItemOB item) async {
    final payload = jsonDecode(item.payloadJson) as Map<String, dynamic>;
    final id = item.entityId;

    switch ((item.entityType, item.operationType)) {
      case ('task', 'CREATE'):
        await _dio.post('/tasks', data: payload);
      case ('task', 'UPDATE'):
        await _dio.patch('/tasks/$id', data: payload);
      case ('task', 'TOGGLE'):
        await _dio.post('/tasks/$id/toggle', data: const {});
      case ('task', 'DELETE'):
        await _dio.delete('/tasks/$id');

      case ('subject', 'CREATE'):
        await _dio.post('/subjects', data: payload);
      case ('subject', 'UPDATE'):
        await _dio.patch('/subjects/$id', data: payload);
      case ('subject', 'DELETE'):
        await _dio.delete('/subjects/$id');

      case ('attendance_session', 'CREATE'):
        final subjectId = payload['subject_id'] as String;
        await _dio.post('/subjects/$subjectId/sessions', data: payload);
      case ('attendance_session', 'DELETE'):
        final subjectId = payload['subject_id'] as String;
        await _dio.delete('/subjects/$subjectId/sessions/$id');

      default:
        throw StateError(
          'Unhandled sync operation: ${item.entityType}/${item.operationType}',
        );
    }
  }

  /// True when the server has given a verdict that retrying cannot change.
  ///
  /// 404 on a delete and 409 on a create are treated as already-done rather than
  /// failures, and are handled by the caller removing the item either way.
  bool _isPermanent(DioException e) {
    final status = e.response?.statusCode;
    if (status == null) return false; // network/timeout — worth retrying

    // Rate limited or request timeout: transient by definition.
    if (status == 408 || status == 429) return false;
    // Server-side problems may resolve on their own.
    if (status >= 500) return false;

    return status >= 400;
  }

  int get failedCount {
    final q = _store
        .box<SyncQueueItemOB>()
        .query(SyncQueueItemOB_.status.equals('failed'))
        .build();
    final c = q.count();
    q.close();
    return c;
  }

  /// Clears items that exhausted their retries, so a later manual retry or a
  /// fresh sign-in starts from a clean slate.
  void clearFailed() {
    final box = _store.box<SyncQueueItemOB>();
    final q = box.query(SyncQueueItemOB_.status.equals('failed')).build();
    final failed = q.find();
    q.close();
    box.removeMany(failed.map((f) => f.obId).toList());
  }

  void dispose() => _sub?.cancel();
}
