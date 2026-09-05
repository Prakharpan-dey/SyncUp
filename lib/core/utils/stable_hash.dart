/// FNV-1a over a string's code units.
///
/// Dart's `String.hashCode` is not guaranteed stable across SDK releases or
/// platforms. That matters wherever a hash outlives the process: an avatar
/// colour would change after an upgrade, and — worse — a notification scheduled
/// under one hash could never be cancelled under another, leaving an alarm
/// firing forever with nothing able to reach it.
int stableHash(String value) {
  var hash = 0x811c9dc5;
  for (final unit in value.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash;
}

/// A stable notification id for [key].
///
/// Android notification ids are signed 32-bit, so the top bit is masked off.
int notificationIdFor(String key) => stableHash(key) & 0x7FFFFFFF;
