import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_summary.dart';
import '../repositories/social_repository.dart';

class SearchUsersUseCase {
  final SocialRepository _repo;
  SearchUsersUseCase(this._repo);

  Future<Either<Failure, List<UserSummary>>> call(String query) async {
    if (query.trim().length < 2) {
      return const Right([]);
    }
    return _repo.searchUsers(query.trim());
  }
}
