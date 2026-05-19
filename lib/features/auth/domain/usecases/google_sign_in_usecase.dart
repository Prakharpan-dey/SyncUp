import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repositories.dart';

class GoogleSignInUseCase {
  final AuthRepository _repo;
  GoogleSignInUseCase(this._repo);

  Future<Either<Failure, User>> call() async {
    return _repo.signInWithGoogle();
  }
}
