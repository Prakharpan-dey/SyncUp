import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:syncup/core/theme/app_theme.dart';
import 'package:syncup/features/attendance/domain/entities/attendance_session.dart';
import 'package:syncup/features/attendance/domain/entities/subject.dart';
import 'package:syncup/features/attendance/presentation/screens/subject_detail_screen.dart';
import 'package:syncup/features/attendance/presentation/viewmodels/attendance_viewmodel.dart';

/// Serves a fixed state; the banner is pure arithmetic over it.
class _StubAttendanceViewModel extends AttendanceViewModel {
  _StubAttendanceViewModel(this._seed);
  final AttendanceState _seed;

  @override
  AttendanceState build() => _seed;

  @override
  Future<void> loadSessions(String subjectId) async {}
}

void main() {
  final stamp = DateTime(2026, 9, 1);

  final subject = Subject(
    id: 's1',
    userId: 'u1',
    name: 'Data Structures',
    thresholdPct: 75,
    createdAt: stamp,
    updatedAt: stamp,
  );

  List<AttendanceSession> sessions({required int attended, required int total}) => [
        for (var i = 0; i < total; i++)
          AttendanceSession(
            id: 'x$i',
            subjectId: 's1',
            sessionDate: DateTime(2026, 9, i + 1),
            status: i < attended
                ? AttendanceStatus.present
                : AttendanceStatus.absent,
            createdAt: stamp,
            updatedAt: stamp,
          ),
      ];

  Future<void> pumpDetail(
    WidgetTester tester, {
    required int attended,
    required int total,
  }) async {
    final vm = _StubAttendanceViewModel(AttendanceState(
      subjects: [subject],
      sessions: sessions(attended: attended, total: total),
    ));
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

  group('with no classes to spare', () {
    /// The bug: one miss away from dropping under 75%, the banner said
    /// "You're right at 75%" — beneath a big 100%.
    testWidgets('at 1 of 1 it warns about the next miss, not the threshold',
        (tester) async {
      await pumpDetail(tester, attended: 1, total: 1);

      expect(find.text('NO SKIPS LEFT'), findsOneWidget);
      expect(find.text('Miss the next class and you drop under 75%.'),
          findsOneWidget);
      expect(find.text('AT THRESHOLD'), findsNothing);
      expect(find.textContaining('right at'), findsNothing);
    });

    testWidgets('exactly at the threshold reads the same way', (tester) async {
      // 3 of 4 is 75%; one miss gives 3 of 5, which is 60%.
      await pumpDetail(tester, attended: 3, total: 4);

      expect(find.text('NO SKIPS LEFT'), findsOneWidget);
    });
  });

  testWidgets('a buffer still reads as SAFE TO SKIP', (tester) async {
    // 7 of 8 is 88%; one miss gives 7 of 9 (78%), two gives 7 of 10 (70%).
    await pumpDetail(tester, attended: 7, total: 8);

    expect(find.text('SAFE TO SKIP: 1'), findsOneWidget);
    expect(find.text('NO SKIPS LEFT'), findsNothing);
  });
}
