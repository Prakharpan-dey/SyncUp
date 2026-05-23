import 'package:fpdart/fpdart.dart' hide Group;
import '../../../../core/error/failures.dart';
import '../entities/group.dart';
import '../repositories/social_repository.dart';

class CreateGroupUseCase {
  final SocialRepository _repo;
  CreateGroupUseCase(this._repo);

  Future<Either<Failure, Group>> call({
    required String name,
    required String createdBy,
  }) async {
    if (name.trim().isEmpty) {
      return const Left(ValidationFailure('Group name is required'));
    }
    if (name.trim().length > 100) {
      return const Left(
          ValidationFailure('Group name must be 100 characters or less'));
    }
    return _repo.createGroup(name: name.trim(), createdBy: createdBy);
  }
}
