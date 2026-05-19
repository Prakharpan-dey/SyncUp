import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repositories.dart';

class GetCurrentUserUseCase {
  final AuthRepository _repo;
  GetCurrentUserUseCase(this._repo);

  Future<Either<Failure, User?>> call() async {
    return _repo.getCurrentUser();
  }
}
