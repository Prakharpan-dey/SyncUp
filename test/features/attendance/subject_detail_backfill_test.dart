import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:syncup/core/theme/app_theme.dart';
import 'package:syncup/features/attendance/domain/entities/attendance_session.dart';
import 'package:syncup/features/attendance/domain/entities/subject.dart';
import 'package:syncup/features/attendance/presentation/screens/subject_detail_screen.dart';
import 'package:syncup/features/attendance/presentation/viewmodels/attendance_viewmodel.dart';

/// Records what the screen asks for instead of touching a repository.
class _StubAttendanceViewModel extends AttendanceViewModel {
  _StubAttendanceViewModel(this._seed);
  final AttendanceState _seed;

  final List<DateTime> loggedDates = [];
  final List<AttendanceStatus> loggedStatuses = [];

  @override
  AttendanceState build() => _seed;

  @override
  Future<void> loadSessions(String subjectId) async {}

  @override
  Future<void> logAttendance({
    required String subjectId,
    required DateTime date,
    required AttendanceStatus status,
  }) async {
    loggedDates.add(date);
    loggedStatuses.add(status);
  }
}

void main() {
  DateTime midnight(DateTime d) => DateTime(d.year, d.month, d.day);
  final today = midnight(DateTime.now());

  final subject = Subject(
    id: 's1',
    userId: 'u1',
    name: 'Thermodynamics',
    thresholdPct: 75,
    createdAt: today,
    updatedAt: today,
  );

  late _StubAttendanceViewModel vm;

  Future<void> pumpDetail(WidgetTester tester) async {
    vm = _StubAttendanceViewModel(AttendanceState(subjects: [subject]));
    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const SubjectDetailScreen(subjectId: 's1'),
      ),
    ]);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: ProviderContainer(
          overrides: [attendanceViewModelProvider.overrideWith(() => vm)],
        ),
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Picks a past date through the real date picker and returns what was
  /// chosen. Deliberately date-independent: on the 1st of a month there is no
  /// earlier day on the page the picker opens to, so it steps back a month.
  Future<DateTime> pickPastDate(WidgetTester tester) async {
    await tester.tap(find.text('MARKING FOR'));
    await tester.pumpAndSettle();

    late final DateTime expected;
    if (today.day > 1) {
      expected = DateTime(today.year, today.month, 1);
    } else {
      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();
      final prev = DateTime(today.year, today.month - 1, 15);
      expected = prev;
    }
    await tester.tap(find.text('${expected.day}').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    return expected;
  }

  group('which day attendance is recorded against', () {
    testWidgets('says it is marking today by default', (tester) async {
      await pumpDetail(tester);

      expect(find.text('MARKING FOR'), findsOneWidget);
      expect(find.text('TODAY'), findsOneWidget);
    });

    testWidgets('records today when nothing is changed', (tester) async {
      await pumpDetail(tester);

      await tester.tap(find.text('PRESENT'));
      await tester.pump();

      expect(vm.loggedDates.single, today);
      expect(vm.loggedStatuses.single, AttendanceStatus.present);
    });

    /// The whole point: a class you forgot to mark on the day was previously
    /// unrecordable, because both buttons passed DateTime.now().
    testWidgets('records the chosen past day instead of today',
        (tester) async {
      await pumpDetail(tester);

      final chosen = await pickPastDate(tester);

      await tester.tap(find.text('ABSENT'));
      await tester.pump();

      expect(vm.loggedDates.single, chosen);
      expect(vm.loggedStatuses.single, AttendanceStatus.absent);
    });

    testWidgets('offers a way back to today once a past day is chosen',
        (tester) async {
      await pumpDetail(tester);
      expect(find.text('BACK TO TODAY'), findsNothing);

      await pickPastDate(tester);

      expect(find.text('BACK TO TODAY'), findsOneWidget);

      await tester.tap(find.text('BACK TO TODAY'));
      await tester.pumpAndSettle();

      expect(find.text('TODAY'), findsOneWidget);
      expect(find.text('BACK TO TODAY'), findsNothing);
    });
  });
}
