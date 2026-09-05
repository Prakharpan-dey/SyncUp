import 'package:flutter_test/flutter_test.dart';
import 'package:syncup/features/tasks/domain/entities/task.dart';
import 'package:syncup/features/tasks/domain/entities/task_series.dart';
import 'package:syncup/features/tasks/domain/usecases/generate_occurrences_usecase.dart';

void main() {
  final today = DateTime(2026, 9, 7); // a Monday
  final horizon = today.add(const Duration(days: kGenerationHorizonDays));

  TaskSeries seriesWith({
    Set<int> weekdays = const {1, 2, 3, 4, 5, 6, 7},
    DateTime? startsOn,
    DateTime? endsOn,
    DateTime? generatedThrough,
  }) =>
      TaskSeries(
        id: 's1',
        userId: 'u1',
        title: 'Take medicine',
        weekdays: weekdays,
        dueMinutes: 9 * 60,
        startsOn: startsOn ?? today,
        endsOn: endsOn,
        generatedThrough: generatedThrough,
        createdAt: today,
        updatedAt: today,
      );

  List<DateTime> plan(TaskSeries s) =>
      plannedDays(s, today: today, horizonEnd: horizon);

  group('which days a rule produces', () {
    test('a daily rule fills every day of the horizon', () {
      // Inclusive of both ends: today through today+14.
      expect(plan(seriesWith()), hasLength(kGenerationHorizonDays + 1));
    });

    test('chosen weekdays produce only those days', () {
      final days = plan(seriesWith(weekdays: {1, 3, 5}));

      expect(days.map((d) => d.weekday).toSet(), {1, 3, 5});
      expect(days, isNotEmpty);
    });

    test('a single weekday produces one day per week', () {
      final days = plan(seriesWith(weekdays: {2}));

      // A 15-day window spans either two or three Tuesdays.
      expect(days.length, inInclusiveRange(2, 3));
      expect(days.every((d) => d.weekday == DateTime.tuesday), isTrue);
    });

    test('nothing before the series starts', () {
      final days = plan(seriesWith(startsOn: today.add(const Duration(days: 5))));

      expect(days.first, today.add(const Duration(days: 5)));
    });

    test('an end date truncates the horizon', () {
      final days = plan(seriesWith(endsOn: today.add(const Duration(days: 3))));

      expect(days, hasLength(4)); // today .. today+3
      expect(days.last, today.add(const Duration(days: 3)));
    });

    test('a series that already ended produces nothing', () {
      expect(plan(seriesWith(endsOn: today.subtract(const Duration(days: 1)))),
          isEmpty);
    });
  });

  group('the watermark', () {
    /// Regenerating on every app open must not re-emit what already exists.
    test('a fully generated series plans nothing more', () {
      expect(plan(seriesWith(generatedThrough: horizon)), isEmpty);
    });

    test('resumes the day after the watermark, not from the start', () {
      final days = plan(seriesWith(
        startsOn: today.subtract(const Duration(days: 10)),
        generatedThrough: today.add(const Duration(days: 2)),
      ));

      expect(days.first, today.add(const Duration(days: 3)));
    });

    /// A device restored from an old backup would otherwise materialise
    /// hundreds of missed days at once and bury the list.
    test('backfill is capped however stale the watermark is', () {
      final days = plan(seriesWith(
        startsOn: today.subtract(const Duration(days: 400)),
        generatedThrough: today.subtract(const Duration(days: 300)),
      ));

      expect(days.first,
          today.subtract(const Duration(days: kMaxBackfillDays)));
    });

    test('the cap never pulls generation earlier than the series start', () {
      final startsOn = today.subtract(const Duration(days: 3));
      final days = plan(seriesWith(startsOn: startsOn));

      expect(days.first, startsOn);
    });
  });

  group('occurrence ids', () {
    /// The whole idempotency story rests on this: same series, same day, same
    /// id — across runs, devices and reinstalls.
    test('are stable for the same series and day', () {
      expect(occurrenceId('s1', today), occurrenceId('s1', today));
    });

    test('differ per day', () {
      expect(occurrenceId('s1', today),
          isNot(occurrenceId('s1', today.add(const Duration(days: 1)))));
    });

    test('differ per series', () {
      expect(occurrenceId('s1', today), isNot(occurrenceId('s2', today)));
    });

    test('ignore a time component on the day', () {
      expect(occurrenceId('s1', DateTime(2026, 9, 7)),
          occurrenceId('s1', DateTime(2026, 9, 7, 13, 45)));
    });

    // The API validates this field as a uuid, so a bare hash would 422.
    test('are real uuids', () {
      expect(
        occurrenceId('s1', today),
        matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}-'
            r'[89ab][0-9a-f]{3}-[0-9a-f]{12}$')),
      );
    });
  });

  group('what an occurrence inherits', () {
    test('carries the series time so it can be reminded about', () {
      final s = seriesWith();
      expect(s.dueMinutes, 9 * 60);
      expect(s.repeatsOn(today), isTrue);
    });

    test('a daily rule reports itself as daily', () {
      expect(seriesWith().isDaily, isTrue);
      expect(seriesWith(weekdays: {1, 3, 5}).isDaily, isFalse);
    });
  });

  group('a generated occurrence behaves like a task', () {
    Task occurrence(DateTime day, {int? minutes}) => Task(
          id: occurrenceId('s1', day),
          userId: 'u1',
          title: 'Take medicine',
          dueDate: day,
          dueMinutes: minutes,
          seriesId: 's1',
          createdAt: today,
          updatedAt: today,
        );

    test('reads as recurring', () {
      expect(occurrence(today).isRecurring, isTrue);
    });

    test('is due at its own time, not midnight', () {
      expect(occurrence(today, minutes: 9 * 60).dueAt, DateTime(2026, 9, 7, 9));
    });
  });
}
