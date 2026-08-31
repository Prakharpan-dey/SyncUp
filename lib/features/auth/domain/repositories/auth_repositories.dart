import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/auth_session.dart';
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
  Future<Either<Failure, void>> logout();

  /// Requires the current password — deletion is irreversible.
  Future<Either<Failure, void>> deleteAccount(String password);

  Future<Either<Failure, User>> updateProfile(Map<String, dynamic> fields);
  Future<Either<Failure, User?>> getCurrentUser();

  /// Re-sends the verification link. Resolves to true if already verified.
  Future<Either<Failure, bool>> requestEmailVerification();
  Future<Either<Failure, void>> confirmEmailVerification(String token);

  /// Always succeeds when the request is well-formed, whether or not the
  /// address is registered — the API deliberately does not say which.
  Future<Either<Failure, void>> forgotPassword(String email);

  Future<Either<Failure, void>> resetPassword({
    required String token,
    required String password,
  });

  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Devices with a live session, newest first.
  Future<Either<Failure, List<AuthSession>>> getSessions();

  /// Signs out one other device.
  Future<Either<Failure, void>> revokeSession(String sessionId);

  /// Signs out every device, including this one.
  Future<Either<Failure, void>> logoutAll();

  /// Registers this device for push. Claims the token, so it moves if another
  /// account previously owned it.
  Future<void> registerDevice({
    required String fcmToken,
    required String platform,
  });
}
