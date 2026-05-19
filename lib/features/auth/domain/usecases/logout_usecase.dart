import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../repositories/auth_repositories.dart';

class LogoutUseCase {
  final AuthRepository _repo;
  LogoutUseCase(this._repo);

  Future<Either<Failure, void>> call() async {
    return _repo.logout();
  }
}
