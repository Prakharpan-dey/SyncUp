import 'package:flutter_test/flutter_test.dart';
import 'package:syncup/core/sync/pull_merge.dart';

void main() {
  final earlier = DateTime(2026, 9, 14, 9);
  final later = DateTime(2026, 9, 14, 10);

  LocalRow local(String id, {bool synced = true, DateTime? at}) =>
      (id: id, isSynced: synced, updatedAt: at ?? earlier);
  RemoteRow remote(String id, {DateTime? at}) => (id: id, updatedAt: at ?? earlier);

  /// A reinstall left the device empty and nothing ever read the server back.
  test('an empty device takes everything the server has', () {
    final plan = planPull(
      local: const [],
      remote: [remote('a'), remote('b')],
      queued: const {},
    );
    expect(plan.take, {'a', 'b'});
    expect(plan.remove, isEmpty);
  });

  test('leaves a row with an upload still queued', () {
    final plan = planPull(
      local: [local('a', synced: false)],
      remote: [remote('a')],
      queued: const {'a'},
    );
    expect(plan.take, isEmpty);
  });

  test('keeps an unsynced edit newer than the server copy', () {
    final plan = planPull(
      local: [local('a', synced: false, at: later)],
      remote: [remote('a', at: earlier)],
      queued: const {},
    );
    expect(plan.take, isEmpty);
  });

  test('takes the server copy when it is the newer one', () {
    final plan = planPull(
      local: [local('a', synced: false, at: earlier)],
      remote: [remote('a', at: later)],
      queued: const {},
    );
    expect(plan.take, {'a'});
  });

  test('removes an uploaded row the server no longer has', () {
    final plan = planPull(
      local: [local('gone')],
      remote: const [],
      queued: const {},
    );
    expect(plan.remove, {'gone'});
  });

  test('never removes a row that has not been uploaded yet', () {
    final plan = planPull(
      local: [local('new', synced: false)],
      remote: const [],
      queued: const {},
    );
    expect(plan.remove, isEmpty);
  });

  test('does not bring back a delete still waiting to upload', () {
    final plan = planPull(
      local: const [],
      remote: [remote('deleted')],
      queued: const {'deleted'},
    );
    expect(plan.take, isEmpty);
  });
}
