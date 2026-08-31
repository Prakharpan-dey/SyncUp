import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:syncup/core/network/auth_interceptor.dart';

class _MockStorage extends Mock implements FlutterSecureStorage {}

/// A Dio adapter that answers from a script instead of the network, and counts
/// how many times each path was hit.
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.respond);

  final Future<ResponseBody> Function(RequestOptions options) respond;
  final List<String> calls = [];

  int callsTo(String path) => calls.where((c) => c == path).length;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls.add(options.path);
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Map<String, dynamic> body, int status) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

void main() {
  late _MockStorage storage;

  setUp(() {
    storage = _MockStorage();
    when(() => storage.read(key: any(named: 'key')))
        .thenAnswer((_) async => 'stored-refresh-token');
    when(() => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        )).thenAnswer((_) async {});
    when(() => storage.deleteAll()).thenAnswer((_) async {});
  });

  /// Wires an interceptor onto a Dio whose adapter is scripted, sharing one
  /// adapter with the refresh client so every call lands in the same counter.
  ({Dio api, AuthInterceptor interceptor, _StubAdapter adapter}) build({
    required Future<ResponseBody> Function(RequestOptions) respond,
  }) {
    final adapter = _StubAdapter(respond);

    final refreshDio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = adapter;
    final interceptor = AuthInterceptor(storage, refreshDio: refreshDio);

    final api = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = adapter
      ..interceptors.add(interceptor);

    return (api: api, interceptor: interceptor, adapter: adapter);
  }

  group('concurrent 401s', () {
    /// The bug this exists for. A screen fires several requests at once, so
    /// when the access token expires they 401 together. Refreshing per-request
    /// meant each posted the same refresh token separately; the server rotates
    /// on every call, so the chain forked and the client kept whichever reply
    /// landed last — already revoked by the others. The next refresh tripped
    /// reuse detection and killed the session, which is why the app appeared to
    /// sign itself out after a few hours.
    test('three simultaneous 401s trigger exactly one refresh', () async {
      var refreshed = false;

      final t = build(respond: (options) async {
        if (options.path == '/auth/refresh') {
          refreshed = true;
          return _json({
            'access_token': 'fresh-access',
            'refresh_token': 'fresh-refresh',
          }, 200);
        }
        // Unauthorised until the refresh lands, fine afterwards.
        return refreshed
            ? _json({'ok': true}, 200)
            : _json({'message': 'Unauthorized'}, 401);
      });

      await Future.wait([
        t.api.get<dynamic>('/tasks'),
        t.api.get<dynamic>('/feed'),
        t.api.get<dynamic>('/subjects'),
      ]);

      expect(t.adapter.callsTo('/auth/refresh'), 1);
    });

    test('every waiting request is retried once the refresh lands', () async {
      var refreshed = false;
      final t = build(respond: (options) async {
        if (options.path == '/auth/refresh') {
          refreshed = true;
          return _json({
            'access_token': 'fresh-access',
            'refresh_token': 'fresh-refresh',
          }, 200);
        }
        return refreshed
            ? _json({'ok': true}, 200)
            : _json({'message': 'Unauthorized'}, 401);
      });

      final results = await Future.wait([
        t.api.get<dynamic>('/tasks'),
        t.api.get<dynamic>('/feed'),
      ]);

      expect(results.every((r) => r.statusCode == 200), isTrue);
    });

    test('the refreshed token is persisted for later requests', () async {
      var refreshed = false;
      final t = build(respond: (options) async {
        if (options.path == '/auth/refresh') {
          refreshed = true;
          return _json({
            'access_token': 'fresh-access',
            'refresh_token': 'fresh-refresh',
          }, 200);
        }
        return refreshed
            ? _json({'ok': true}, 200)
            : _json({'message': 'Unauthorized'}, 401);
      });

      await t.api.get<dynamic>('/tasks');

      verify(() => storage.write(key: 'access_token', value: 'fresh-access'))
          .called(1);
      verify(() => storage.write(key: 'refresh_token', value: 'fresh-refresh'))
          .called(1);
    });
  });

  group('unrecoverable session', () {
    /// Previously the interceptor cleared storage and said nothing: auth state
    /// still read as signed in, the router never redirected, and the user sat
    /// in a working-looking app where nothing loaded.
    test('a failed refresh announces the expiry exactly once', () async {
      final t = build(respond: (options) async {
        if (options.path == '/auth/refresh') {
          return _json({'message': 'Refresh token reuse detected'}, 401);
        }
        return _json({'message': 'Unauthorized'}, 401);
      });

      var expiries = 0;
      final sub = t.interceptor.onSessionExpired.listen((_) => expiries++);

      await t.api.get<dynamic>('/tasks').catchError((Object e) => throw e).catchError(
        (Object _) => Response<dynamic>(requestOptions: RequestOptions(path: '/tasks')),
      );
      await Future<void>.delayed(Duration.zero);

      expect(expiries, 1);
      verify(() => storage.deleteAll()).called(1);
      await sub.cancel();
    });

    test('with no stored refresh token it gives up immediately', () async {
      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);

      final t = build(
        respond: (_) async => _json({'message': 'Unauthorized'}, 401),
      );

      var expiries = 0;
      final sub = t.interceptor.onSessionExpired.listen((_) => expiries++);

      await t.api.get<dynamic>('/tasks').catchError(
        (Object _) => Response<dynamic>(requestOptions: RequestOptions(path: '/tasks')),
      );
      await Future<void>.delayed(Duration.zero);

      // Nothing to refresh with, so no attempt is made.
      expect(t.adapter.callsTo('/auth/refresh'), 0);
      expect(expiries, 1);
      await sub.cancel();
    });

    /// A 401 from the refresh endpoint must not re-enter the interceptor.
    test('does not recurse when the refresh itself 401s', () async {
      final t = build(
        respond: (_) async => _json({'message': 'Unauthorized'}, 401),
      );

      await t.api.get<dynamic>('/tasks').catchError(
        (Object _) => Response<dynamic>(requestOptions: RequestOptions(path: '/tasks')),
      );

      expect(t.adapter.callsTo('/auth/refresh'), 1);
    });
  });

  group('token handling', () {
    test('attaches the access token once saved', () async {
      final t = build(respond: (_) async => _json({'ok': true}, 200));
      await t.interceptor.saveTokens(
        accessToken: 'abc',
        refreshToken: 'def',
      );

      final res = await t.api.get<dynamic>('/tasks');
      expect(res.requestOptions.headers['Authorization'], 'Bearer abc');
    });

    /// saveTokens is the single entry point on purpose: writing to storage
    /// alone left the in-memory token null on a fresh install, so every request
    /// after sign-in went out unauthenticated until the app was restarted.
    test('clearTokens drops the header as well as storage', () async {
      final t = build(respond: (_) async => _json({'ok': true}, 200));
      await t.interceptor.saveTokens(accessToken: 'abc', refreshToken: 'def');
      await t.interceptor.clearTokens();

      final res = await t.api.get<dynamic>('/tasks');
      expect(res.requestOptions.headers.containsKey('Authorization'), isFalse);
    });

    test('sends no Authorization header before any token exists', () async {
      final t = build(respond: (_) async => _json({'ok': true}, 200));
      final res = await t.api.get<dynamic>('/tasks');
      expect(res.requestOptions.headers.containsKey('Authorization'), isFalse);
    });
  });
}
