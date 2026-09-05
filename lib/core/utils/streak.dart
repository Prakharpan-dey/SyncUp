import '../../features/tasks/domain/entities/task.dart';

/// Streak maths over completed tasks, shared by the home and tasks screens.
///
/// This lived as a private `_calculateStreak` duplicated byte-for-byte in both
/// screens. Beyond the duplication, it started counting at *today*, so before
/// the first tick of the day a forty-day streak read zero all morning.

/// The distinct days on which anything was completed, newest first.
List<DateTime> completionDays(List<Task> tasks) {
  final days = tasks
      .where((t) => t.isCompleted && t.completedAt != null)
      .map((t) => DateTime(
            t.completedAt!.year,
            t.completedAt!.month,
            t.completedAt!.day,
          ))
      .toSet()
      .toList()
    ..sort((a, b) => b.compareTo(a));
  return days;
}

/// Consecutive days completed, counting back from today.
///
/// A day that has not been ticked *yet* does not break the streak — the day is
/// not over. So the walk starts at today if today has a completion, and at
/// yesterday otherwise. Only a genuinely skipped day ends it.
int currentStreak(List<Task> tasks, {DateTime? now}) {
  final days = completionDays(tasks);
  if (days.isEmpty) return 0;

  final today = _dayOf(now ?? DateTime.now());
  final yesterday = today.subtract(const Duration(days: 1));

  var cursor = days.first == today ? today : yesterday;
  // The most recent completion is older than yesterday: the run is already over.
  if (days.first != cursor) return 0;

  var streak = 0;
  for (final day in days) {
    if (day == cursor) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    } else if (day.isBefore(cursor)) {
      break;
    }
  }
  return streak;
}

/// The longest run of consecutive completed days ever recorded.
///
/// The tasks screen previously passed [currentStreak] for both the current and
/// the best figure, so "BEST" could never exceed today's run and dropped
/// whenever a day was missed.
int longestStreak(List<Task> tasks) {
  final days = completionDays(tasks);
  if (days.isEmpty) return 0;

  var longest = 1;
  var run = 1;
  // Newest first, so each step back should be exactly one day earlier.
  for (var i = 1; i < days.length; i++) {
    final expected = days[i - 1].subtract(const Duration(days: 1));
    if (days[i] == expected) {
      run++;
      if (run > longest) longest = run;
    } else {
      run = 1;
    }
  }
  return longest;
}

DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);
