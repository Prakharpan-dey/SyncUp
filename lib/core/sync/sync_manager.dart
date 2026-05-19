import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:syncup/objectbox.g.dart';

import '../storage/models/sync_queue_item_ob.dart';
import '../storage/object_box_store.dart';
import '../constants/app_constants.dart';
import 'connectivity_service.dart';

class SyncManager {
  final ObjectBoxStore _store;
  final ConnectivityService _connectivity;
  bool _isProcessing = false; // mutex
  StreamSubscription? _sub;

  SyncManager(this._store, this._connectivity) {
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
      // TODO: API call based on entityType + operationType
      box.remove(item.obId);
    } catch (e) {
      item.retryCount++;
      item.status = item.retryCount >= AppConstants.syncMaxRetries
          ? 'failed'
          : 'pending';
      box.put(item);
      if (item.status == 'pending') {
        await Future.delayed(
          Duration(seconds: pow(2, item.retryCount).toInt()),
        );
      }
    }
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

  void dispose() => _sub?.cancel();
}
