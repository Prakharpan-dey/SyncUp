import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'guest_session.dart';

/// The id that local (ObjectBox) rows are keyed by for the current session.
///
/// Replaces the `'current-user'` / `'local-user'` placeholders that were
/// scattered through the screens. Those two literals disagreed — subjects were
/// written under one and read back under the other, so the home screen's
/// attendance section could never find anything.
///
/// Resolves to the real account id when signed in, the guest id in guest mode.
/// Falls back to the stored guest id during the brief window before auth
/// resolves on cold start, so early queries do not read from a phantom bucket.
final currentUserIdProvider = Provider<String>((ref) {
  final auth = ref.watch(authViewModelProvider);

  final accountId = auth.user?.id;
  if (auth.status == AuthStatus.authenticated && accountId != null) {
    return accountId;
  }

  return auth.guestId ?? ref.watch(guestSessionProvider) ?? _unresolved;
});

/// Sentinel for "no session yet". Deliberately not a valid id, so any row
/// written under it is visibly wrong rather than silently mixed into real data.
const _unresolved = 'unresolved-user';
