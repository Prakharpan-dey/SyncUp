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

  /// Brings the account's subjects and classes down from the server.
  /// Right(true) when the device's copy changed.
  ///
  /// [repairIds] runs the one-time repair for installs from before the server
  /// kept the app's ids: it uploads what only this phone has, then drops the
  /// empty duplicates the server made back then.
  Future<Either<Failure, bool>> pullFromServer(String userId,
      {bool repairIds = false});
}
