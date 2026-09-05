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

  /// `'HH:mm'` from minutes past midnight — the wire format for `due_time`.
  ///
  /// Local wall-clock, with no timezone attached: the server stores it opaquely
  /// and only the device, which knows its own zone, turns it into an alarm.
  static String formatApiTime(int minutesPastMidnight) {
    final h = (minutesPastMidnight ~/ 60).toString().padLeft(2, '0');
    final m = (minutesPastMidnight % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Minutes past midnight from `'HH:mm'`, or null if absent or malformed.
  static int? parseApiTime(String? hhmm) {
    if (hhmm == null) return null;
    final parts = hhmm.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) return null;
    return h * 60 + m;
  }

  static String formatRelative(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return formatDate(date);
  }
}
