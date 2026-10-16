import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncup/core/error/failures.dart';
import 'package:syncup/core/theme/theme_mode_provider.dart';
import 'package:syncup/features/attendance/di/attendance_providers.dart';
import 'package:syncup/features/attendance/domain/entities/subject.dart';
import 'package:syncup/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:syncup/features/attendance/presentation/viewmodels/attendance_viewmodel.dart';
import 'package:syncup/features/auth/domain/entities/user.dart';
import 'package:syncup/features/auth/presentation/viewmodels/auth_viewmodel.dart';

class _MockAttendanceRepo extends Mock implements AttendanceRepository {}

const userId = 'u1';

class _SignedIn extends AuthViewModel {
  @override
  AuthState build() => const AuthState(
        status: AuthStatus.authenticated,
        user: User(
          id: userId,
          username: 'rhea',
          displayName: 'Rhea',
          email: 'rhea@example.com',
          privacySharingDefault: 'summary',
        ),
      );
}

class _Guest extends AuthViewModel {
  @override
  AuthState build() => const AuthState(status: AuthStatus.guest);
}

final dbms = Subject(
  id: 's1',
  userId: userId,
  name: 'DBMS',
  createdAt: DateTime(2026, 10),
  updatedAt: DateTime(2026, 10),
);

/// Attendance was read from the device only: a reinstall or a new phone showed
/// "No subjects yet" for an account whose subjects were on the server.
void main() {
  late _MockAttendanceRepo repo;
  late SharedPreferences prefs;

  setUp(() async {
    repo = _MockAttendanceRepo();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    when(() => repo.getSessionsForSubject(any()))
        .thenAnswer((_) async => const Right([]));
  });

  ProviderContainer make(AuthViewModel Function() auth) {
    final c = ProviderContainer(overrides: [
      attendanceRepositoryProvider.overrideWithValue(repo),
      sharedPrefsProvider.overrideWithValue(prefs),
      authViewModelProvider.overrideWith(auth),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  test('a fresh install signed in pulls, shows what arrived, and repairs once',
      () async {
    var onDevice = <Subject>[];
    when(() => repo.getSubjects(userId)).thenAnswer((_) async => Right(onDevice));
    when(() => repo.pullFromServer(userId, repairIds: any(named: 'repairIds')))
        .thenAnswer((_) async {
      onDevice = [dbms];
      return const Right(true);
    });

    final c = make(_SignedIn.new);
    await c.read(attendanceViewModelProvider.notifier).loadSubjects(userId);

    expect(c.read(attendanceViewModelProvider).subjects, [dbms]);
    verify(() => repo.pullFromServer(userId, repairIds: true)).called(1);

    // Repaired and freshly pulled: a plain load now stays on the device.
    await c.read(attendanceViewModelProvider.notifier).loadSubjects(userId);
    verifyNever(() => repo.pullFromServer(userId, repairIds: true));
    verifyNever(() => repo.pullFromServer(userId, repairIds: false));

    // Pull-to-refresh always asks, without repairing again.
    await c
        .read(attendanceViewModelProvider.notifier)
        .loadSubjects(userId, refresh: true);
    verify(() => repo.pullFromServer(userId, repairIds: false)).called(1);
  });

  test('a failed pull leaves the repair to try again next time', () async {
    when(() => repo.getSubjects(userId)).thenAnswer((_) async => Right([dbms]));
    when(() => repo.pullFromServer(userId, repairIds: any(named: 'repairIds')))
        .thenAnswer((_) async => const Left(NetworkFailure('Offline')));

    final c = make(_SignedIn.new);
    await c.read(attendanceViewModelProvider.notifier).loadSubjects(userId);
    await c.read(attendanceViewModelProvider.notifier).loadSubjects(userId);

    verify(() => repo.pullFromServer(userId, repairIds: true)).called(2);
    expect(c.read(attendanceViewModelProvider).subjects, [dbms]);
  });

  test("a guest's subjects live on the device, so nothing is fetched", () async {
    when(() => repo.getSubjects(userId)).thenAnswer((_) async => const Right([]));

    final c = make(_Guest.new);
    await c.read(attendanceViewModelProvider.notifier).loadSubjects(userId);

    verifyNever(() => repo.pullFromServer(any(), repairIds: any(named: 'repairIds')));
  });
}
