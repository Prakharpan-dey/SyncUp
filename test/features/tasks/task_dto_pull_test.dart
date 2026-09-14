import 'package:flutter_test/flutter_test.dart';
import 'package:syncup/features/tasks/data/models/task_dto.dart';
import 'package:syncup/features/tasks/domain/entities/task.dart';

void main() {
  /// A task exactly as `GET /tasks` sends it.
  Map<String, dynamic> row({String? completedAt}) => {
        'id': 't1',
        'user_id': 'u1',
        'title': 'Revise DBMS',
        'priority': 'high',
        'status': completedAt != null ? 'completed' : 'pending',
        'tags': ['exam'],
        'due_date': '2026-09-14',
        'due_time': '09:30',
        'series_id': 's1',
        'completed_at': completedAt,
        'created_at': '2026-09-01T04:00:00.000Z',
        'updated_at': '2026-09-14T04:00:00.000Z',
      };

  /// Pulled back after a reinstall, the completion history is what the streak
  /// and weekly recap are built from.
  test('reads back a task the server holds', () {
    final task = TaskDto.fromJson(row()).toDomain();

    expect(task.dueDate, DateTime(2026, 9, 14));
    expect(task.dueMinutes, 9 * 60 + 30);
    expect(task.seriesId, 's1');
    expect(task.priority, TaskPriority.high);
    expect(task.createdAt, DateTime.utc(2026, 9, 1, 4).toLocal());
    expect(task.updatedAt, DateTime.utc(2026, 9, 14, 4).toLocal());
  });

  test('keeps when it was completed, in local time', () {
    final task =
        TaskDto.fromJson(row(completedAt: '2026-09-14T04:00:00.000Z')).toDomain();

    expect(task.isCompleted, isTrue);
    expect(task.completedAt!.isUtc, isFalse);
    expect(task.completedAt, DateTime.utc(2026, 9, 14, 4).toLocal());
  });
}
