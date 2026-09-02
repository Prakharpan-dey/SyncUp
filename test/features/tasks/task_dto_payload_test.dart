import 'package:flutter_test/flutter_test.dart';
import 'package:syncup/features/tasks/data/models/task_dto.dart';
import 'package:syncup/features/tasks/domain/entities/task.dart';

/// The API validates optional fields with Zod `.optional()`, which accepts an
/// absent key and rejects an explicit null with a 422. Sending nulls made every
/// create and update fail for a task without a description and due date — which
/// is the default path — and the repository's silent catch hid it.
void main() {
  Task taskWith({String? description, DateTime? dueDate}) => Task(
        id: 't1',
        userId: 'u1',
        title: 'Finish DBMS assignment',
        description: description,
        dueDate: dueDate,
        priority: TaskPriority.medium,
        status: TaskStatus.pending,
        createdAt: DateTime(2026, 9, 1),
        updatedAt: DateTime(2026, 9, 1),
      );

  group('optional fields the API would reject as null', () {
    test('omits description and due date when unset', () {
      final json = TaskDto.fromDomain(taskWith()).toJson();

      expect(json.containsKey('description'), isFalse);
      expect(json.containsKey('due_date'), isFalse);
    });

    test('omits completed_at while the task is pending', () {
      expect(
        TaskDto.fromDomain(taskWith()).toJson().containsKey('completed_at'),
        isFalse,
      );
    });

    test('sends them when they are set', () {
      final json = TaskDto.fromDomain(
        taskWith(description: 'Chapter 4', dueDate: DateTime(2026, 9, 10)),
      ).toJson();

      expect(json['description'], 'Chapter 4');
      expect(json['due_date'], '2026-09-10');
    });

    test('never carries a null value at all', () {
      final json = TaskDto.fromDomain(taskWith()).toJson();

      expect(json.values.where((v) => v == null), isEmpty);
    });
  });

  group('the fields the API always requires', () {
    test('are present even on the barest task', () {
      final json = TaskDto.fromDomain(taskWith()).toJson();

      expect(json['title'], 'Finish DBMS assignment');
      expect(json['priority'], 'medium');
      expect(json['tags'], isEmpty);
    });
  });
}
