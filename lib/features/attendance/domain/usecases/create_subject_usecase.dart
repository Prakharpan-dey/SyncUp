import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/error/failures.dart';
import '../entities/subject.dart';
import '../repositories/attendance_repository.dart';

class CreateSubjectUseCase {
  final AttendanceRepository _repo;
  CreateSubjectUseCase(this._repo);

  Future<Either<Failure, Subject>> call({
    required String userId,
    required String name,
    String? code,
    int thresholdPct = 75,
  }) async {
    if (name.trim().isEmpty) {
      return const Left(ValidationFailure('Subject name is required'));
    }
    if (thresholdPct < 0 || thresholdPct > 100) {
      return const Left(ValidationFailure('Threshold must be between 0 and 100'));
    }
    final subject = Subject(
      id: const Uuid().v4(),
      userId: userId,
      name: name.trim(),
      code: code?.trim(),
      thresholdPct: thresholdPct,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return _repo.createSubject(subject);
  }
}
