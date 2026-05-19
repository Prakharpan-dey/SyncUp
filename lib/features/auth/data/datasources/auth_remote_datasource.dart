import 'package:dio/dio.dart';

class AuthRemoteDataSource {
  final Dio _dio;
  AuthRemoteDataSource(this._dio);

  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    final res = await _dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    final res = await _dio.post(
      '/auth/signup',
      data: {
        'email': email,
        'password': password,
        'username': username,
        'display_name': displayName,
      },
    );
    return res.data as Map<String, dynamic>;
  }

  Future<void> logout() => _dio.post('/auth/logout');
  Future<void> deleteAccount() => _dio.post('/auth/delete');

  Future<Map<String, dynamic>> signInWithGoogle({
    required String idToken,
  }) async {
    final res = await _dio.post(
      '/auth/google',
      data: {'id_token': idToken},
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getMe() async {
    final res = await _dio.get('/auth/me');
    return res.data as Map<String, dynamic>;
  }
}
