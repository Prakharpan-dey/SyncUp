import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/core_providers.dart';
import '../data/datasources/attendance_remote_datasource.dart';
import '../data/repositories/attendance_repository_impl.dart';
import '../domain/repositories/attendance_repository.dart';
import '../domain/usecases/create_subject_usecase.dart';
import '../domain/usecases/log_attendance_usecase.dart';
import '../domain/usecases/calculate_classes_needed.dart';
import '../domain/usecases/calculate_safe_to_skip.dart';

final attendanceRemoteDataSourceProvider = Provider((ref) =>
    AttendanceRemoteDataSource(ref.watch(dioClientProvider).dio));

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) =>
    AttendanceRepositoryImpl(
      ref.watch(attendanceRemoteDataSourceProvider),
      ref.watch(objectBoxStoreProvider),
      ref.watch(syncManagerProvider),
      ref.watch(connectivityServiceProvider),
    ));

final createSubjectUseCaseProvider = Provider((ref) =>
    CreateSubjectUseCase(ref.watch(attendanceRepositoryProvider)));

final logAttendanceUseCaseProvider = Provider((ref) =>
    LogAttendanceUseCase(ref.watch(attendanceRepositoryProvider)));

final calculateClassesNeededProvider = Provider((_) =>
    CalculateClassesNeeded());

final calculateSafeToSkipProvider = Provider((_) =>
    CalculateSafeToSkip());
