import 'package:intl/intl.dart';

class DateHelpers {
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  static bool isThisWeek(DateTime date) {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    final end = start.add(const Duration(days: 6));
    return date.isAfter(start.subtract(const Duration(days: 1))) &&
        date.isBefore(end.add(const Duration(days: 1)));
  }

  static String formatDate(DateTime date) => DateFormat.yMMMd().format(date);

  /// Calendar date as `YYYY-MM-DD`, the wire format the API expects for
  /// `due_date` and `session_date`. Those map to Postgres `date` columns, so
  /// sending a full ISO timestamp fails validation.
  static String formatApiDate(DateTime date) =>
      DateFormat('yyyy-MM-dd').format(date);

  static String formatRelative(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return formatDate(date);
  }
}
