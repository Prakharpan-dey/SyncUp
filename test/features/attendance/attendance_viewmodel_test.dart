import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:syncup/core/error/failures.dart';
import 'package:syncup/features/attendance/di/attendance_providers.dart';
import 'package:syncup/features/attendance/domain/entities/attendance_session.dart';
import 'package:syncup/features/attendance/domain/entities/subject.dart';
import 'package:syncup/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:syncup/features/attendance/presentation/viewmodels/attendance_viewmodel.dart';

class _MockAttendanceRepo extends Mock implements AttendanceRepository {}

const userId = 'u1';
const dsa = 'subject-dsa';
const os = 'subject-os';

final stamp = DateTime(2026, 9, 1);

Subject subject(String id, String name) => Subject(
      id: id,
      userId: userId,
      name: name,
      createdAt: stamp,
      updatedAt: stamp,
    );

AttendanceSession session(
  String id,
  String subjectId, {
  required int day,
  bool present = true,
}) =>
    AttendanceSession(
      id: id,
      subjectId: subjectId,
      sessionDate: DateTime(2026, 9, day),
      status: present ? AttendanceStatus.present : AttendanceStatus.absent,
      createdAt: stamp,
      updatedAt: stamp,
    );

void main() {
  late _MockAttendanceRepo repo;
  late ProviderContainer container;

  AttendanceViewModel vm() => container.read(attendanceViewModelProvider.notifier);
  AttendanceState state() => container.read(attendanceViewModelProvider);

  // DSA: 2 of 3 attended. OS: 3 of 4 attended (75%).
  final dsaSessions = [
    session('d1', dsa, day: 1),
    session('d2', dsa, day: 2),
    session('d3', dsa, day: 3, present: false),
  ];
  final osSessions = [
    session('o1', os, day: 1),
    session('o2', os, day: 2),
    session('o3', os, day: 3),
    session('o4', os, day: 4, present: false),
  ];

  setUpAll(() => registerFallbackValue(session('fallback', dsa, day: 1)));

  setUp(() {
    repo = _MockAttendanceRepo();
    container = ProviderContainer(overrides: [
      attendanceRepositoryProvider.overrideWithValue(repo),
    ]);

    when(() => repo.getSubjects(userId)).thenAnswer((_) async => Right([
          subject(dsa, 'Data Structures'),
          subject(os, 'Operating Systems'),
        ]));
    when(() => repo.getSessionsForSubject(dsa))
        .thenAnswer((_) async => Right(dsaSessions));
    when(() => repo.getSessionsForSubject(os))
        .thenAnswer((_) async => Right(osSessions));
  });

  tearDown(() => container.dispose());

  group('the subject list after opening a subject', () {
    /// The bug: opening a subject's detail screen replaced the shared session
    /// list with that subject's sessions alone, so back on the list every other
    /// subject read "No classes logged" until the app restarted.
    test("keeps every other subject's classes and percentage", () async {
      await vm().loadSubjects(userId);
      expect(state().totalClasses(os), 4, reason: 'precondition: list loaded');

      await vm().loadSessions(dsa);

      expect(state().totalClasses(os), 4);
      expect(state().attendedClasses(os), 3);
      expect(state().attendancePercentage(os), 75);
    });

    test("still shows the opened subject's own figures", () async {
      await vm().loadSubjects(userId);

      await vm().loadSessions(dsa);

      expect(state().totalClasses(dsa), 3);
      expect(state().attendedClasses(dsa), 2);
    });

    /// Reopening must swap the subject's sessions in, not append them — or
    /// every visit would double its class count.
    test("refreshes the opened subject without duplicating it", () async {
      await vm().loadSubjects(userId);
      when(() => repo.getSessionsForSubject(dsa)).thenAnswer((_) async => Right([
            ...dsaSessions,
            session('d4', dsa, day: 4),
          ]));

      await vm().loadSessions(dsa);
      await vm().loadSessions(dsa);

      expect(state().totalClasses(dsa), 4);
      expect(state().totalClasses(os), 4);
    });

    test('keeps sessions newest first', () async {
      await vm().loadSubjects(userId);

      await vm().loadSessions(dsa);

      final dates = state().sessions.map((s) => s.sessionDate).toList();
      final sorted = [...dates]..sort((a, b) => b.compareTo(a));
      expect(dates, sorted);
    });

    test('a failed load leaves the list as it was', () async {
      await vm().loadSubjects(userId);
      when(() => repo.getSessionsForSubject(dsa))
          .thenAnswer((_) async => const Left(CacheFailure('disk error')));

      await vm().loadSessions(dsa);

      expect(state().error, 'disk error');
      expect(state().totalClasses(dsa), 3);
      expect(state().totalClasses(os), 4);
    });
  });

  group('marking from a detail screen', () {
    test('counts the new session without dropping other subjects', () async {
      when(() => repo.logSession(any()))
          .thenAnswer((i) async => Right(i.positionalArguments.first));
      await vm().loadSubjects(userId);
      await vm().loadSessions(dsa);

      await vm().logAttendance(
        subjectId: dsa,
        date: DateTime.now(),
        status: AttendanceStatus.present,
      );

      expect(state().totalClasses(dsa), 4);
      expect(state().totalClasses(os), 4);
    });

    test('undo removes only that session', () async {
      when(() => repo.deleteSession('d3'))
          .thenAnswer((_) async => const Right(null));
      await vm().loadSubjects(userId);
      await vm().loadSessions(dsa);

      await vm().deleteSession('d3');

      expect(state().totalClasses(dsa), 2);
      expect(state().attendancePercentage(dsa), 100);
      expect(state().totalClasses(os), 4);
    });
  });

  /// `loadSubjects` used to return before its sessions were loaded — the
  /// success branch was async and never awaited — so a caller awaiting it
  /// (pull-to-refresh) saw an empty list.
  test('loadSubjects has every subject loaded once it returns', () async {
    await vm().loadSubjects(userId);

    expect(state().isLoading, isFalse);
    expect(state().subjects, hasLength(2));
    expect(state().totalClasses(dsa), 3);
    expect(state().totalClasses(os), 4);
  });
}
