import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../repositories/auth_repositories.dart';

class DeleteAccountUseCase {
  final AuthRepository _repo;
  DeleteAccountUseCase(this._repo);

  Future<Either<Failure, void>> call(String password) async {
    if (password.isEmpty) {
      return const Left(ValidationFailure('Enter your password to confirm'));
    }
    return _repo.deleteAccount(password);
  }
}
