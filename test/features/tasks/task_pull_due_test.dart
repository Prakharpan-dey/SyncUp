import 'package:flutter_test/flutter_test.dart';
import 'package:syncup/features/tasks/presentation/viewmodels/task_viewmodel.dart';

/// Every screen load asked the server for the whole task list. The device's
/// copy is what the screens read, so a plain load now asks only now and then.
void main() {
  final now = DateTime(2026, 9, 15, 12);

  test('asks the server on first use of this install', () {
    expect(pullDue(null, now), isTrue);
  });

  test('trusts the device for a few hours after asking', () {
    expect(pullDue(now.subtract(const Duration(minutes: 5)), now), isFalse);
    expect(pullDue(now.subtract(const Duration(hours: 5)), now), isFalse);
  });

  test('asks again once that has passed', () {
    expect(pullDue(now.subtract(kTaskPullInterval), now), isTrue);
    expect(pullDue(now.subtract(const Duration(days: 2)), now), isTrue);
  });
}
