import 'package:flutter_test/flutter_test.dart';
import 'package:syncup/core/router/deep_link_handler.dart';

void main() {
  String? route(String uri) => DeepLinkHandler.toRoute(Uri.parse(uri));

  group('group invites', () {
    /// The custom scheme puts the first segment in the host and the rest in
    /// path segments; the https form puts everything in path segments. Both
    /// must normalize to the same in-app route.
    test('resolves the custom scheme', () {
      expect(route('syncup://groups/join/abc123'), '/groups/join/abc123');
    });

    test('resolves the https form identically', () {
      expect(
        route('https://syncup.app/groups/join/abc123'),
        '/groups/join/abc123',
      );
    });

    test('rejects an invite with no token', () {
      expect(route('syncup://groups/join'), isNull);
    });
  });

  group('emailed auth links', () {
    /// These carry the token in the query string, not the path. They used to be
    /// dropped with a debugPrint, which silently broke verification and reset —
    /// the two flows that arrive only by email.
    test('resolves email verification', () {
      expect(
        route('syncup://auth/verify-email?token=tok123'),
        '/auth/verify-email?token=tok123',
      );
    });

    test('resolves password reset', () {
      expect(
        route('syncup://auth/reset-password?token=tok123'),
        '/auth/reset-password?token=tok123',
      );
    });

    test('percent-encodes a token containing URL metacharacters', () {
      final result = route('syncup://auth/reset-password?token=a b&c');
      expect(result, startsWith('/auth/reset-password?token='));
      expect(result, isNot(contains(' ')));
      // A raw & would otherwise read as a second query parameter.
      expect(result!.split('token=').last, isNot(contains('&c')));
    });

    test('rejects an auth link with no token', () {
      expect(route('syncup://auth/verify-email'), isNull);
    });

    test('rejects an auth link with an empty token', () {
      expect(route('syncup://auth/verify-email?token='), isNull);
    });

    test('rejects an unknown auth action', () {
      expect(route('syncup://auth/delete-everything?token=x'), isNull);
    });
  });

  group('links that are not ours', () {
    test('ignores an unrelated host', () {
      expect(route('https://example.com/groups/join/abc'), isNull);
    });

    test('ignores an empty URI', () {
      expect(route('syncup://'), isNull);
    });

    test('ignores an unknown first segment', () {
      expect(route('syncup://billing/upgrade'), isNull);
    });
  });
}
