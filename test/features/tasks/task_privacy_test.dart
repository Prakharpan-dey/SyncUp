import 'package:flutter_test/flutter_test.dart';
import 'package:syncup/features/tasks/data/models/task_dto.dart';
import 'package:syncup/features/tasks/domain/entities/task.dart';

void main() {
  final stamp = DateTime(2026, 9, 5);

  Task task({String? sharingOverride}) => Task(
        id: 't1',
        userId: 'u1',
        title: 'Therapy appointment',
        sharingOverride: sharingOverride,
        createdAt: stamp,
        updatedAt: stamp,
      );

  group('a task kept private', () {
    /// The control existed on the wire and in the client model but the server
    /// never read it, so marking one task private did nothing. Now that the
    /// server honours it, the client has to actually be able to send it.
    test('reaches the API as sharing_override', () {
      final json = TaskDto.fromDomain(task(sharingOverride: 'none')).toJson();

      expect(json['sharing_override'], 'none');
    });

    test('is reported as private by the entity', () {
      expect(task(sharingOverride: 'none').isPrivate, isTrue);
    });

    test('an ordinary task is not private', () {
      expect(task().isPrivate, isFalse);
      expect(task(sharingOverride: 'inherit').isPrivate, isFalse);
    });
  });

  group('the wire shape', () {
    /// The API validates optional fields with Zod .optional(), which rejects an
    /// explicit null — the invariant the payload test guards.
    test('omits sharing_override when the task inherits', () {
      final json = TaskDto.fromDomain(task()).toJson();

      expect(json.containsKey('sharing_override'), isFalse);
      expect(json.values.where((v) => v == null), isEmpty);
    });

    test('round-trips through fromJson', () {
      final json = TaskDto.fromDomain(task(sharingOverride: 'summary')).toJson();
      final back = TaskDto.fromJson({
        ...json,
        'user_id': 'u1',
        'created_at': stamp.toIso8601String(),
      }).toDomain();

      expect(back.sharingOverride, 'summary');
    });
  });

  group('copyWith', () {
    test('can clear the override back to inheriting', () {
      final private = task(sharingOverride: 'none');

      expect(private.copyWith(sharingOverride: null).sharingOverride, isNull);
    });

    test('leaves it alone when not mentioned', () {
      final private = task(sharingOverride: 'none');

      expect(private.copyWith(title: 'Renamed').sharingOverride, 'none');
    });

    /// props must include it, or a list would reuse the old element and keep
    /// rendering a task as shared after it was made private.
    test('changing it makes the task compare unequal', () {
      final before = task();

      expect(before.copyWith(sharingOverride: 'none'), isNot(before));
    });
  });
}
