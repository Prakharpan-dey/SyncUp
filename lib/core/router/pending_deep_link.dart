import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds a deep link that arrived before the user was allowed to follow it.
///
/// Tapping a group invite while signed out sends the router's redirect to
/// `/auth/sign-in`, which would otherwise discard the token — the user signs in
/// and lands on `/home` with no idea the invite existed. Stashing it here lets
/// the router replay it once authentication resolves.
class PendingDeepLink extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String route) => state = route;

  /// Returns the stored route and clears it, so a replayed link fires once.
  String? consume() {
    final route = state;
    state = null;
    return route;
  }
}

final pendingDeepLinkProvider =
    NotifierProvider<PendingDeepLink, String?>(PendingDeepLink.new);
