import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:syncup/features/auth/domain/repositories/auth_repositories.dart';
import '../../../../core/auth/device_label.dart';
import '../../../../core/network/auth_interceptor.dart';
import '../../../../core/notifications/push_service.dart';
import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/user.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_session_dto.dart';
import '../models/user_dto.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;
  final FlutterSecureStorage _storage;
  final DeviceLabelService _deviceLabel;

  /// Owns the in-memory access token as well as the stored one, so the two
  /// cannot drift apart.
  final AuthInterceptor _interceptor;


  AuthRepositoryImpl(
    this._remote,
    this._storage,
    this._deviceLabel,
    this._interceptor,
  );


  @override
  Future<Either<Failure, User>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final data = await _remote.signIn(
        email: email,
        password: password,
        deviceLabel: await _deviceLabel.resolve(),
      );
      await _interceptor.saveTokens(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String,
      );
      return Right(UserDto.fromJson(data['user']).toDomain());
    } on DioException catch (e) {
      return Left(ErrorMapper.fromDioException(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> signUp({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    try {
      final data = await _remote.signUp(
        email: email,
        password: password,
        username: username,
        displayName: displayName,
        deviceLabel: await _deviceLabel.resolve(),
      );
      await _interceptor.saveTokens(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String,
      );
      return Right(UserDto.fromJson(data['user']).toDomain());
    } on DioException catch (e) {
      return Left(ErrorMapper.fromDioException(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }


  @override
  Future<Either<Failure, void>> logout() async {
    try {
      // Send the refresh token so only this device is signed out; without it
      // the server ends every session the user has. The push token goes too,
      // so a signed-out handset stops receiving this account's notifications —
      // on a shared device they would otherwise leak to whoever signs in next.
      final refreshToken = await _storage.read(key: 'refresh_token');
      await _remote.logout(
        refreshToken: refreshToken,
        fcmToken: await currentPushToken(),
      );
      await _interceptor.clearTokens();
      return const Right(null);
    } on DioException catch (e) {
      return Left(ErrorMapper.fromDioException(e));
    } catch (e) {
      // Even if server call fails, clear local state
      await _interceptor.clearTokens();
      return const Right(null);
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount(String password) async {
    try {
      await _remote.deleteAccount(password);
      await _interceptor.clearTokens();
      return const Right(null);
    } on DioException catch (e) {
      return Left(ErrorMapper.fromDioException(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> requestEmailVerification() async {
    try {
      final data = await _remote.requestEmailVerification();
      return Right(data['already_verified'] == true);
    } on DioException catch (e) {
      return Left(ErrorMapper.fromDioException(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> confirmEmailVerification(String token) async {
    try {
      await _remote.confirmEmailVerification(token);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ErrorMapper.fromDioException(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> forgotPassword(String email) async {
    try {
      await _remote.forgotPassword(email);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ErrorMapper.fromDioException(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword({
    required String token,
    required String password,
  }) async {
    try {
      await _remote.resetPassword(token: token, password: password);
      // The server revokes every session on reset, so anything cached locally
      // is already dead.
      await _interceptor.clearTokens();
      return const Right(null);
    } on DioException catch (e) {
      return Left(ErrorMapper.fromDioException(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<void> registerDevice({
    required String fcmToken,
    required String platform,
  }) =>
      // Deliberately not Either: the caller is a background push setup step
      // that already treats failure as "no push on this device".
      _remote.registerDevice(fcmToken: fcmToken, platform: platform);

  @override
  Future<Either<Failure, List<AuthSession>>> getSessions() async {
    try {
      // Sent so the server can mark which entry is this device.
      final refreshToken = await _storage.read(key: 'refresh_token');
      final rows = await _remote.getSessions(refreshToken: refreshToken);
      return Right(
        rows.map((j) => AuthSessionDto.fromJson(j).toDomain()).toList(),
      );
    } on DioException catch (e) {
      return Left(ErrorMapper.fromDioException(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> revokeSession(String sessionId) async {
    try {
      await _remote.revokeSession(sessionId);
      return const Right(null);
    } on DioException catch (e) {
      return Left(ErrorMapper.fromDioException(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logoutAll() async {
    try {
      await _remote.logoutAll();
      await _interceptor.clearTokens();
      return const Right(null);
    } on DioException catch (e) {
      // The session is gone locally either way; a failed call should not strand
      // the user in a signed-in-looking app.
      await _interceptor.clearTokens();
      return Left(ErrorMapper.fromDioException(e));
    } catch (e) {
      await _interceptor.clearTokens();
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _remote.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return const Right(null);
    } on DioException catch (e) {
      return Left(ErrorMapper.fromDioException(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> updateProfile(Map<String, dynamic> fields) async {
    try {
      final data = await _remote.updateProfile(fields);
      return Right(UserDto.fromJson(data['user']).toDomain());
    } on DioException catch (e) {
      return Left(ErrorMapper.fromDioException(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      final token = await _storage.read(key: 'access_token');
      if (token == null) {
        return const Right(null);
      }
      final data = await _remote.getMe();
      return Right(UserDto.fromJson(data['user']).toDomain());
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return const Right(null);
      }
      return Left(ErrorMapper.fromDioException(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
