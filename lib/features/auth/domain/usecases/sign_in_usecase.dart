import 'package:fpdart/fpdart.dart';
import 'package:syncup/features/auth/domain/repositories/auth_repositories.dart';
import '../../../../core/error/failures.dart';
import '../entities/user.dart';

class SignInUseCase {
  final AuthRepository _repo;
  SignInUseCase(this._repo);

  Future<Either<Failure, User>> call({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty) {
      return const Left(ValidationFailure('Email required'));
    }
    if (password.isEmpty) {
      return const Left(ValidationFailure('Password required'));
    }
    return _repo.signIn(email: email.trim(), password: password);
  }
}
