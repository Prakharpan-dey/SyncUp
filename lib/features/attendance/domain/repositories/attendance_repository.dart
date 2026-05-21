import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/subject.dart';
import '../entities/attendance_session.dart';

abstract interface class AttendanceRepository {
  // Subjects
  Future<Either<Failure, List<Subject>>> getSubjects(String userId);
  Future<Either<Failure, Subject>> createSubject(Subject subject);
  Future<Either<Failure, Subject>> updateSubject(Subject subject);
  Future<Either<Failure, void>> deleteSubject(String subjectId);

  // Sessions
  Future<Either<Failure, List<AttendanceSession>>> getSessionsForSubject(
      String subjectId);
  Future<Either<Failure, AttendanceSession>> logSession(
      AttendanceSession session);
  Future<Either<Failure, void>> deleteSession(String sessionId);
}
