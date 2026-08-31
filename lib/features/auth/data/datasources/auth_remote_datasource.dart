import 'package:dio/dio.dart';

class AuthRemoteDataSource {
  final Dio _dio;
  AuthRemoteDataSource(this._dio);

  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
    String? deviceLabel,
  }) async {
    final res = await _dio.post(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
        // Names this session in the user's Devices list. Omitted rather than
        // sent null when it cannot be determined — the field is optional.
        'device_label': ?deviceLabel,
      },
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String username,
    required String displayName,
    String? deviceLabel,
  }) async {
    final res = await _dio.post(
      '/auth/signup',
      data: {
        'email': email,
        'password': password,
        'username': username,
        'display_name': displayName,
        'device_label': ?deviceLabel,
      },
    );
    return res.data as Map<String, dynamic>;
  }

  /// Ends only this device's session.
  ///
  /// The server falls back to signing out everywhere when no refresh token is
  /// supplied, so passing it is what keeps the user's other devices alive.
  Future<void> logout({String? refreshToken, String? fcmToken}) {
    final data = <String, String>{};
    if (refreshToken != null) data['refresh_token'] = refreshToken;
    if (fcmToken != null) data['fcm_token'] = fcmToken;
    return _dio.post('/auth/logout', data: data);
  }

  Future<void> logoutAll() => _dio.post('/auth/logout-all');

  /// The current refresh token is passed so the server can flag which entry
  /// belongs to this device.
  Future<List<Map<String, dynamic>>> getSessions({String? refreshToken}) async {
    final res = await _dio.get(
      '/auth/sessions',
      queryParameters: refreshToken == null
          ? null
          : {'refresh_token': refreshToken},
    );
    return List<Map<String, dynamic>>.from(res.data['sessions'] ?? []);
  }

  Future<void> revokeSession(String sessionId) =>
      _dio.delete('/auth/sessions/$sessionId');

  /// Registers this device for push, taking ownership of the token.
  Future<void> registerDevice({
    required String fcmToken,
    required String platform,
  }) =>
      _dio.post('/auth/devices',
          data: {'fcm_token': fcmToken, 'platform': platform});

  /// Deletion re-authenticates — a stolen access token must not be enough.
  Future<void> deleteAccount(String password) =>
      _dio.post('/auth/delete', data: {'password': password});

  // ── Email verification ──

  Future<Map<String, dynamic>> requestEmailVerification() async {
    final res = await _dio.post('/auth/verify-email/request');
    return res.data as Map<String, dynamic>;
  }

  Future<void> confirmEmailVerification(String token) =>
      _dio.post('/auth/verify-email/confirm', data: {'token': token});

  // ── Password reset ──

  Future<void> forgotPassword(String email) =>
      _dio.post('/auth/forgot-password', data: {'email': email});

  Future<void> resetPassword({
    required String token,
    required String password,
  }) =>
      _dio.post('/auth/reset-password',
          data: {'token': token, 'password': password});

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) =>
      _dio.post('/auth/change-password', data: {
        'current_password': currentPassword,
        'new_password': newPassword,
      });


  Future<Map<String, dynamic>> getMe() async {
    final res = await _dio.get('/auth/me');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> fields) async {
    final res = await _dio.patch('/users/me', data: fields);
    return res.data as Map<String, dynamic>;
  }
}
