import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;
  final Dio _refreshDio;
  String? _accessToken;

  /// Fires when the session ends server-side and cannot be recovered.
  ///
  /// Without this the interceptor would clear the tokens and say nothing: the
  /// auth state would still read as signed in, the router would never redirect,
  /// and every later request would go out unauthenticated. The user would sit
  /// in a working-looking app where nothing loads, with no way back short of
  /// finding Log Out or force-quitting.
  final _sessionExpired = StreamController<void>.broadcast();
  Stream<void> get onSessionExpired => _sessionExpired.stream;

  /// The refresh currently in flight, shared by every request waiting on it.
  Future<String?>? _refreshFuture;

  AuthInterceptor(this._storage)
    : _refreshDio = Dio(
        BaseOptions(
          baseUrl: AppConstants.apiBaseUrl,
          connectTimeout: const Duration(seconds: 10),
        ),
      );

  void dispose() => _sessionExpired.close();

  Future<void> loadToken() async {
    _accessToken = await _storage.read(key: 'access_token');
  }

  /// Persists a freshly issued token pair and puts the access token into use.
  ///
  /// Single entry point on purpose. Writing to secure storage alone used to
  /// leave `_accessToken` holding whatever was loaded at startup — null on a
  /// fresh install — so every request after a sign-in went out with no
  /// Authorization header and came back 401 until the app was restarted.
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
  }

  /// Clears the session locally, in memory and on disk.
  Future<void> clearTokens() async {
    _accessToken = null;
    await _storage.deleteAll();
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_accessToken != null) {
      options.headers['Authorization'] = 'Bearer $_accessToken';
    }
    handler.next(options);
  }

  /// Refreshes the token pair, collapsing concurrent callers onto one request.
  ///
  /// A screen typically fires several requests at once, so when the access
  /// token expires they all 401 together. Refreshing per-request meant each one
  /// posted the same refresh token separately, and since the server rotates on
  /// every call the chain forked: the client kept whichever reply landed last,
  /// while the others had already revoked it. The next refresh then presented a
  /// revoked token well outside the server's reuse grace window, which revokes
  /// the session — the app appeared to sign itself out after a few hours.
  ///
  /// Returns the new access token, or null when the session is unrecoverable.
  Future<String?> _refreshTokens() {
    return _refreshFuture ??= _performRefresh().whenComplete(() {
      _refreshFuture = null;
    });
  }

  Future<String?> _performRefresh() async {
    final refreshToken = await _storage.read(key: 'refresh_token');
    if (refreshToken == null) return null;

    try {
      final response = await _refreshDio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      final newAccess = response.data['access_token'] as String;
      await saveTokens(
        accessToken: newAccess,
        refreshToken: response.data['refresh_token'] as String,
      );
      return newAccess;
    } catch (_) {
      // Revoked, expired, or the account is gone.
      await clearTokens();
      return null;
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 &&
        !err.requestOptions.path.contains('/auth/refresh')) {
      final newAccess = await _refreshTokens();
      if (newAccess == null) {
        _endSession();
        handler.next(err);
        return;
      }

      err.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
      try {
        handler.resolve(await _refreshDio.fetch(err.requestOptions));
      } on DioException catch (e) {
        handler.next(e);
      }
      return;
    }
    handler.next(err);
  }

  void _endSession() {
    if (!_sessionExpired.isClosed) _sessionExpired.add(null);
  }
}
