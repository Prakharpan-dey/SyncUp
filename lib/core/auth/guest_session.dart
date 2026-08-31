import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../theme/theme_mode_provider.dart' show sharedPrefsProvider;

const _guestIdKey = 'guest_user_id';
const _guestActiveKey = 'guest_mode_active';

/// Tracks the local-only identity used when someone skips sign-in.
///
/// The generated UUID is what local ObjectBox rows are keyed by, so it must stay
/// stable across launches — regenerating it would orphan every task and subject
/// the guest created. It is kept even after guest mode ends so that a later
/// sign-up can find and re-key that data (see [GuestDataMigrator]).
///
/// State is the active guest id, or null when not in guest mode.
class GuestSession extends Notifier<String?> {
  @override
  String? build() {
    final prefs = ref.watch(sharedPrefsProvider);
    final active = prefs.getBool(_guestActiveKey) ?? false;
    return active ? prefs.getString(_guestIdKey) : null;
  }

  /// Enters guest mode, reusing the existing local identity if there is one.
  Future<String> start() async {
    final prefs = ref.read(sharedPrefsProvider);

    var id = prefs.getString(_guestIdKey);
    if (id == null) {
      id = const Uuid().v4();
      await prefs.setString(_guestIdKey, id);
    }

    await prefs.setBool(_guestActiveKey, true);
    state = id;
    return id;
  }

  /// Leaves guest mode. The guest id itself is deliberately retained so local
  /// data can still be migrated after signing in.
  Future<void> end() async {
    await ref.read(sharedPrefsProvider).setBool(_guestActiveKey, false);
    state = null;
  }

  /// The stored guest id whether or not guest mode is currently active.
  String? get storedId =>
      ref.read(sharedPrefsProvider).getString(_guestIdKey);

  /// Forgets the local identity entirely. Only for a full reset — any local
  /// rows still keyed to it become unreachable.
  Future<void> clear() async {
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.remove(_guestIdKey);
    await prefs.remove(_guestActiveKey);
    state = null;
  }
}

final guestSessionProvider =
    NotifierProvider<GuestSession, String?>(GuestSession.new);
