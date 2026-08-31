import 'package:flutter_test/flutter_test.dart';
import 'package:syncup/core/utils/date_helpers.dart';

void main() {
  group('formatApiDate', () {
    /// The API takes YYYY-MM-DD for attendance and task dates. Sending a full
    /// ISO timestamp was rejected, so this is a wire contract, not a display
    /// choice.
    test('emits a bare calendar date, never a timestamp', () {
      final formatted = DateHelpers.formatApiDate(DateTime(2026, 8, 31, 14, 30));
      expect(formatted, '2026-08-31');
      expect(formatted, isNot(contains('T')));
    });

    test('zero-pads single-digit months and days', () {
      expect(DateHelpers.formatApiDate(DateTime(2026, 1, 5)), '2026-01-05');
    });

    test('is stable across times of day', () {
      expect(
        DateHelpers.formatApiDate(DateTime(2026, 3, 9, 0, 0)),
        DateHelpers.formatApiDate(DateTime(2026, 3, 9, 23, 59)),
      );
    });
  });

  group('isToday', () {
    test('is true for now', () {
      expect(DateHelpers.isToday(DateTime.now()), isTrue);
    });
    test('is false for yesterday', () {
      expect(
        DateHelpers.isToday(DateTime.now().subtract(const Duration(days: 1))),
        isFalse,
      );
    });
  });
}
