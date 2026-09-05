import 'package:flutter_test/flutter_test.dart';
import 'package:syncup/features/tasks/domain/entities/task.dart';
import 'package:syncup/features/tasks/presentation/viewmodels/task_viewmodel.dart';

void main() {
  final now = DateTime(2026, 9, 5, 10, 0);
  DateTime day(int offset) => DateTime(2026, 9, 5 + offset);

  Task occurrence({
    required String id,
    required String seriesId,
    required DateTime dueDate,
    int? dueMinutes,
    bool completed = false,
  }) =>
      Task(
        id: id,
        userId: 'u1',
        title: 'Take medicine',
        dueDate: dueDate,
        dueMinutes: dueMinutes,
        seriesId: seriesId,
        status: completed ? TaskStatus.completed : TaskStatus.pending,
        completedAt: completed ? dueDate : null,
        createdAt: now,
        updatedAt: now,
      );

  Task oneOff({required String id, DateTime? dueDate}) => Task(
        id: id,
        userId: 'u1',
        title: 'Submit report',
        dueDate: dueDate,
        createdAt: now,
        updatedAt: now,
      );

  /// A fortnight of occurrences is materialized up front so reminders work
  /// offline, but the list is a to-do list — creating one daily habit used to
  /// put fourteen identical rows under UPCOMING.
  group('a repeating task in the pending list', () {
    List<Task> dailyFortnight() => [
          for (var i = 0; i < 14; i++)
            occurrence(id: 'o$i', seriesId: 's1', dueDate: day(i)),
        ];

    test('appears once, not once per generated day', () {
      final visible = TaskListState(tasks: dailyFortnight()).visiblePending(now: now);

      expect(visible, hasLength(1));
      expect(visible.single.id, 'o0');
    });

    test('the row shown is the soonest one still ahead', () {
      // Deliberately out of order: generation writes in date order, but state
      // is rebuilt from ObjectBox and from optimistic inserts at the head.
      final visible = TaskListState(tasks: [
        occurrence(id: 'friday', seriesId: 's1', dueDate: day(4)),
        occurrence(id: 'tomorrow', seriesId: 's1', dueDate: day(1)),
        occurrence(id: 'thursday', seriesId: 's1', dueDate: day(3)),
      ]).visiblePending(now: now);

      expect(visible.single.id, 'tomorrow');
    });

    test('two separate series each keep their own row', () {
      final visible = TaskListState(tasks: [
        ...dailyFortnight(),
        for (var i = 0; i < 14; i++)
          occurrence(id: 'g$i', seriesId: 's2', dueDate: day(i)),
      ]).visiblePending(now: now);

      expect(visible.map((t) => t.seriesId).toSet(), {'s1', 's2'});
      expect(visible, hasLength(2));
    });

    test('today stays visible until it is actually late', () {
      // Due at 18:00, read at 10:00 — today's occurrence is the one to show,
      // and tomorrow's must not take its place.
      final visible = TaskListState(tasks: [
        occurrence(id: 'today', seriesId: 's1', dueDate: day(0), dueMinutes: 18 * 60),
        occurrence(id: 'tomorrow', seriesId: 's1', dueDate: day(1), dueMinutes: 18 * 60),
      ]).visiblePending(now: now);

      expect(visible.single.id, 'today');
    });

    test('completing today reveals tomorrow rather than nothing', () {
      final visible = TaskListState(tasks: [
        occurrence(id: 'today', seriesId: 's1', dueDate: day(0), completed: true),
        occurrence(id: 'tomorrow', seriesId: 's1', dueDate: day(1)),
      ]).visiblePending(now: now);

      expect(visible.single.id, 'tomorrow');
    });

    test('a weekly task with nothing due today still shows its next day', () {
      final visible = TaskListState(tasks: [
        occurrence(id: 'nextMon', seriesId: 's1', dueDate: day(5)),
        occurrence(id: 'monAfter', seriesId: 's1', dueDate: day(12)),
      ]).visiblePending(now: now);

      expect(visible.single.id, 'nextMon');
    });
  });

  group('days already missed', () {
    /// They are real work the user did not do, they live in their own
    /// collapsed section, and folding them away would put rows beyond the
    /// reach of ticking or deleting.
    test('are each kept, alongside the next one still ahead', () {
      final visible = TaskListState(tasks: [
        occurrence(id: 'mon', seriesId: 's1', dueDate: day(-3)),
        occurrence(id: 'tue', seriesId: 's1', dueDate: day(-2)),
        occurrence(id: 'wed', seriesId: 's1', dueDate: day(-1)),
        occurrence(id: 'today', seriesId: 's1', dueDate: day(0)),
        occurrence(id: 'tomorrow', seriesId: 's1', dueDate: day(1)),
      ]).visiblePending(now: now);

      expect(visible.map((t) => t.id).toSet(), {'mon', 'tue', 'wed', 'today'});
    });

    test('a completed past day is not resurrected as pending', () {
      final visible = TaskListState(tasks: [
        occurrence(id: 'mon', seriesId: 's1', dueDate: day(-3), completed: true),
        occurrence(id: 'today', seriesId: 's1', dueDate: day(0)),
      ]).visiblePending(now: now);

      expect(visible.single.id, 'today');
    });
  });

  group('one-off tasks', () {
    test('are never collapsed against each other', () {
      final visible = TaskListState(tasks: [
        oneOff(id: 'a', dueDate: day(1)),
        oneOff(id: 'b', dueDate: day(2)),
        oneOff(id: 'c'),
      ]).visiblePending(now: now);

      expect(visible.map((t) => t.id).toSet(), {'a', 'b', 'c'});
    });

    test('an undated one survives next to a collapsed series', () {
      final visible = TaskListState(tasks: [
        oneOff(id: 'someday'),
        occurrence(id: 'o0', seriesId: 's1', dueDate: day(0)),
        occurrence(id: 'o1', seriesId: 's1', dueDate: day(1)),
      ]).visiblePending(now: now);

      expect(visible.map((t) => t.id).toSet(), {'someday', 'o0'});
    });
  });
}
