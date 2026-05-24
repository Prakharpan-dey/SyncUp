import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/user.dart';

abstract interface class AuthRepository {
  Future<Either<Failure, User>> signIn({
    required String email,
    required String password,
  });
  Future<Either<Failure, User>> signUp({
    required String email,
    required String password,
    required String username,
    required String displayName,
  });
  Future<Either<Failure, User>> signInWithGoogle();
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, void>> deleteAccount();
  Future<Either<Failure, User>> updateProfile(Map<String, dynamic> fields);
  Future<Either<Failure, User?>> getCurrentUser();
}
