import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

/// Routes incoming deep links into the app.
///
/// Handles two shapes, both mapping to the same in-app route:
/// `syncup://groups/join/{token}` and `https://syncup.app/groups/join/{token}`.
///
/// Covers both the cold-start link (app launched by the link) and links that
/// arrive while the app is already running.
class DeepLinkHandler {
  final AppLinks _appLinks;
  final GoRouter _router;
  StreamSubscription<Uri>? _subscription;

  DeepLinkHandler(this._router) : _appLinks = AppLinks();

  Future<void> init() async {
    // Link that launched the app, if any.
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _handle(initial);
    } catch (e) {
      debugPrint('DeepLinkHandler: failed to read initial link: $e');
    }

    // Links delivered while the app is running.
    _subscription = _appLinks.uriLinkStream.listen(
      _handle,
      onError: (Object e) => debugPrint('DeepLinkHandler: stream error: $e'),
    );
  }

  void _handle(Uri uri) {
    final route = toRoute(uri);
    if (route != null) {
      _router.go(route);
    } else {
      debugPrint('DeepLinkHandler: unrecognized link $uri');
    }
  }

  /// Maps an incoming URI to an in-app route, or null if it isn't one we own.
  ///
  /// The custom scheme puts the first segment in the host and the rest in path
  /// segments, while the https form puts everything in path segments —
  /// normalize both before matching.
  /// The only web host whose links this app will act on.
  ///
  /// The manifest's verified App Link filter is already scoped to it, so the OS
  /// will not hand us another domain's link — but `toRoute` is also reachable
  /// from anything that produces a URI, and honouring `https://anywhere/groups/
  /// join/x` as a genuine invite is not a decision worth leaving implicit.
  static const _webHost = 'syncup.app';

  @visibleForTesting
  static String? toRoute(Uri uri) {
    final isCustomScheme = uri.scheme == 'syncup';
    final isOwnWebLink =
        (uri.scheme == 'https' || uri.scheme == 'http') && uri.host == _webHost;
    if (!isCustomScheme && !isOwnWebLink) return null;

    final segments = <String>[
      if (isCustomScheme && uri.host.isNotEmpty) uri.host,
      ...uri.pathSegments,
    ].where((s) => s.isNotEmpty).toList();

    if (segments.isEmpty) return null;

    // syncup://groups/join/<token>
    if (segments.length == 3 &&
        segments[0] == 'groups' &&
        segments[1] == 'join') {
      return '/groups/join/${segments[2]}';
    }

    // Emailed links carry their token in the query string:
    //   syncup://auth/verify-email?token=…
    //   syncup://auth/reset-password?token=…
    if (segments.length == 2 && segments[0] == 'auth') {
      const emailRoutes = {'verify-email', 'reset-password'};
      if (emailRoutes.contains(segments[1])) {
        final token = uri.queryParameters['token'];
        if (token == null || token.isEmpty) return null;
        return '/auth/${segments[1]}?token=${Uri.encodeQueryComponent(token)}';
      }
    }

    return null;
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
