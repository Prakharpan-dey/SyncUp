import 'package:uuid/uuid.dart';

import '../../../../core/utils/date_helpers.dart';
import '../entities/task.dart';
import '../entities/task_series.dart';
import '../repositories/task_repository.dart';
import '../repositories/task_series_repository.dart';

/// How far ahead occurrences are materialized.
///
/// Rows are cheap, and a generous horizon means someone who does not open the
/// app for two weeks still comes back to real occurrences rather than a gap.
/// Notification scheduling uses a much shorter window of its own — see
/// [TaskNotificationScheduler] — because notification slots are scarce.
const kGenerationHorizonDays = 14;

/// The furthest back a single pass will fill in.
///
/// Without a cap, a device restored from a months-old backup would materialize
/// hundreds of missed days in one go and bury the task list.
const kMaxBackfillDays = 30;

/// Midnight, so date-only comparisons are not thrown off by a time component.
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// The stable id of one occurrence.
///
/// A deterministic UUIDv5 rather than a random id, so regenerating produces the
/// same id and the whole pipeline is idempotent by construction: a duplicate
/// POST lands on the server's `onConflictDoNothing` path, and a device restored
/// from backup does not create a second copy of every occurrence. It is a real
/// UUID, so it satisfies the API's uuid validation.
String occurrenceId(String seriesId, DateTime day) => const Uuid().v5(
      Namespace.url.value,
      'syncup:occurrence:$seriesId:${DateHelpers.formatApiDate(day)}',
    );

/// Materializes the occurrences a set of repeating rules is due to produce.
///
/// Runs on the device rather than the server because the app never hydrates
/// tasks from the API — ObjectBox is what the UI reads, so server-generated
/// rows would simply be invisible.
class GenerateOccurrencesUseCase {
  final TaskRepository _tasks;
  final TaskSeriesRepository _series;

  GenerateOccurrencesUseCase(this._tasks, this._series);

  /// Generates for every active series belonging to [userId].
  ///
  /// Returns how many occurrences were created. Safe to call on every app open:
  /// a second run within the same horizon creates nothing.
  Future<int> call(String userId, {DateTime? now}) async {
    final today = dateOnly(now ?? DateTime.now());

    final seriesResult = await _series.getSeries(userId);
    final allSeries = seriesResult.getOrElse((_) => const []);

    var created = 0;
    for (final series in allSeries.where((s) => s.active)) {
      created += await _generateFor(series, today);
    }
    return created;
  }

  Future<int> _generateFor(TaskSeries series, DateTime today) async {
    final horizonEnd = today.add(const Duration(days: kGenerationHorizonDays));

    final due = plannedDays(series, today: today, horizonEnd: horizonEnd);
    if (due.isEmpty) {
      await _advanceWatermark(series, horizonEnd);
      return 0;
    }

    final candidateIds = {for (final d in due) d: occurrenceId(series.id, d)};
    final existing = _tasks.existingTaskIds(candidateIds.values);

    final fresh = <Task>[];
    final createdAt = DateTime.now();
    for (final day in due) {
      final id = candidateIds[day]!;
      if (existing.contains(id)) continue;
      fresh.add(Task(
        id: id,
        userId: series.userId,
        title: series.title,
        description: series.description,
        dueDate: day,
        priority: series.priority,
        tags: series.tags,
        seriesId: series.id,
        dueMinutes: series.dueMinutes,
        createdAt: createdAt,
        updatedAt: createdAt,
      ));
    }

    if (fresh.isNotEmpty) await _tasks.createOccurrences(fresh);
    await _advanceWatermark(series, horizonEnd);
    return fresh.length;
  }

  /// The watermark only ever moves forward.
  ///
  /// That is what makes deleting a single occurrence permanent: generation
  /// never looks back past it, so nothing already generated is resurrected.
  Future<void> _advanceWatermark(TaskSeries series, DateTime horizonEnd) async {
    final target = series.endsOn != null && series.endsOn!.isBefore(horizonEnd)
        ? series.endsOn!
        : horizonEnd;
    final current = series.generatedThrough;
    if (current != null && !target.isAfter(current)) return;
    await _series.updateSeries(series.copyWith(generatedThrough: target));
  }
}

/// The days [series] should have an occurrence on, between its watermark and
/// [horizonEnd].
///
/// Pure and exported so the rule can be tested without a repository.
List<DateTime> plannedDays(
  TaskSeries series, {
  required DateTime today,
  required DateTime horizonEnd,
}) {
  final earliestBackfill = today.subtract(const Duration(days: kMaxBackfillDays));

  var cursor = series.generatedThrough != null
      ? series.generatedThrough!.add(const Duration(days: 1))
      : series.startsOn;
  if (cursor.isBefore(series.startsOn)) cursor = series.startsOn;
  if (cursor.isBefore(earliestBackfill)) cursor = earliestBackfill;

  final days = <DateTime>[];
  for (var d = dateOnly(cursor);
      !d.isAfter(horizonEnd);
      d = d.add(const Duration(days: 1))) {
    if (series.endsOn != null && d.isAfter(dateOnly(series.endsOn!))) break;
    if (!series.repeatsOn(d)) continue;
    days.add(d);
  }
  return days;
}
