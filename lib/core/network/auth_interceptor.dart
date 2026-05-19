import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;
  final Dio _refreshDio;
  String? _accessToken;

  AuthInterceptor(this._storage)
    : _refreshDio = Dio(
        BaseOptions(
          baseUrl: AppConstants.apiBaseUrl,
          connectTimeout: const Duration(seconds: 10),
        ),
      );

  void setAccessToken(String token) => _accessToken = token;

  Future<void> loadToken() async {
    _accessToken = await _storage.read(key: 'access_token');
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_accessToken != null) {
      options.headers['Authorization'] = 'Bearer $_accessToken';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 &&
        !err.requestOptions.path.contains('/auth/refresh')) {
      try {
        final refreshToken = await _storage.read(key: 'refresh_token');
        if (refreshToken == null) {
          handler.next(err);
          return;
        }

        final response = await _refreshDio.post(
          '/auth/refresh',
          data: {'refresh_token': refreshToken},
        );

        final newAccess = response.data['access_token'] as String;
        final newRefresh = response.data['refresh_token'] as String;

        _accessToken = newAccess;
        await _storage.write(key: 'access_token', value: newAccess);
        await _storage.write(key: 'refresh_token', value: newRefresh);

        err.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
        handler.resolve(await _refreshDio.fetch(err.requestOptions));
        return;
      } catch (_) {
        await _storage.deleteAll();
        _accessToken = null;
      }
    }
    handler.next(err);
  }
}
