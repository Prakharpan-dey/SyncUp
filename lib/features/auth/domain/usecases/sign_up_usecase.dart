import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repositories.dart';

class SignUpUseCase {
  final AuthRepository _repo;
  SignUpUseCase(this._repo);

  Future<Either<Failure, User>> call({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    if (email.trim().isEmpty) {
      return const Left(ValidationFailure('Email required'));
    }
    if (password.length < 8) {
      return const Left(ValidationFailure('Password must be at least 8 characters'));
    }
    if (username.trim().isEmpty) {
      return const Left(ValidationFailure('Username required'));
    }
    if (displayName.trim().isEmpty) {
      return const Left(ValidationFailure('Display name required'));
    }
    return _repo.signUp(
      email: email.trim(),
      password: password,
      username: username.trim(),
      displayName: displayName.trim(),
    );
  }
}
