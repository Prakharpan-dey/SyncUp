import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:syncup/features/auth/domain/repositories/auth_repositories.dart';
import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/constants/env_config.dart';
import '../../domain/entities/user.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_dto.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;
  final FlutterSecureStorage _storage;
  bool _googleInitialized = false;

  AuthRepositoryImpl(this._remote, this._storage);

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    await GoogleSignInPlatform.instance.init(
      InitParameters(
        clientId: EnvConfig.googleClientId,
      ),
    );
    _googleInitialized = true;
  }

  @override
  Future<Either<Failure, User>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final data = await _remote.signIn(email: email, password: password);
      await _storage.write(key: 'access_token', value: data['access_token']);
      await _storage.write(key: 'refresh_token', value: data['refresh_token']);
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
      );
      await _storage.write(key: 'access_token', value: data['access_token']);
      await _storage.write(key: 'refresh_token', value: data['refresh_token']);
      return Right(UserDto.fromJson(data['user']).toDomain());
    } on DioException catch (e) {
      return Left(ErrorMapper.fromDioException(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> signInWithGoogle() async {
    try {
      await _ensureGoogleInitialized();

      // 1. Authenticate with Google
      final AuthenticationResults result =
          await GoogleSignInPlatform.instance.authenticate(
        const AuthenticateParameters(),
      );
      final googleUser = result.user;

      // 2. Get authorization tokens
      final ClientAuthorizationTokenData? tokens =
          await GoogleSignInPlatform.instance
              .clientAuthorizationTokensForScopes(
        ClientAuthorizationTokensForScopesParameters(
          request: AuthorizationRequestDetails(
            scopes: const ['email', 'profile'],
            userId: googleUser.id,
            email: googleUser.email,
            promptIfUnauthorized: true,
          ),
        ),
      );

      if (tokens == null) {
        return const Left(AuthFailure('Failed to get Google auth tokens'));
      }

      // 3. Send token to our backend for verification
      final data = await _remote.signInWithGoogle(
        idToken: tokens.accessToken,
      );
      await _storage.write(key: 'access_token', value: data['access_token']);
      await _storage.write(key: 'refresh_token', value: data['refresh_token']);
      return Right(UserDto.fromJson(data['user']).toDomain());
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return const Left(AuthFailure('Google sign-in cancelled'));
      }
      return Left(AuthFailure('Google sign-in failed: ${e.description}'));
    } on DioException catch (e) {
      return Left(ErrorMapper.fromDioException(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _remote.logout();
      if (_googleInitialized) {
        await GoogleSignInPlatform.instance.disconnect(
          const DisconnectParams(),
        );
      }
      await _storage.deleteAll();
      return const Right(null);
    } on DioException catch (e) {
      return Left(ErrorMapper.fromDioException(e));
    } catch (e) {
      // Even if server call fails, clear local state
      await _storage.deleteAll();
      return const Right(null);
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount() async {
    try {
      await _remote.deleteAccount();
      if (_googleInitialized) {
        await GoogleSignInPlatform.instance.disconnect(
          const DisconnectParams(),
        );
      }
      await _storage.deleteAll();
      return const Right(null);
    } on DioException catch (e) {
      return Left(ErrorMapper.fromDioException(e));
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
