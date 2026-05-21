import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/error/failures.dart';
import '../entities/attendance_session.dart';
import '../repositories/attendance_repository.dart';

class LogAttendanceUseCase {
  final AttendanceRepository _repo;
  LogAttendanceUseCase(this._repo);

  Future<Either<Failure, AttendanceSession>> call({
    required String subjectId,
    required DateTime date,
    required AttendanceStatus status,
  }) async {
    // Reject future dates
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final sessionDate = DateTime(date.year, date.month, date.day);

    if (sessionDate.isAfter(todayDate)) {
      return const Left(
          ValidationFailure('Cannot log attendance for a future date'));
    }

    // Reject dates older than 30 days
    final cutoff = todayDate.subtract(const Duration(days: 30));
    if (sessionDate.isBefore(cutoff)) {
      return const Left(
          ValidationFailure('Cannot backdate attendance beyond 30 days'));
    }

    final session = AttendanceSession(
      id: const Uuid().v4(),
      subjectId: subjectId,
      sessionDate: sessionDate,
      status: status,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return _repo.logSession(session);
  }
}
