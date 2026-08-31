import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/neo_brutalism.dart';

/// A person's avatar, generated rather than uploaded.
///
/// SyncUp stores no images. Instead each account gets initials on a colour
/// derived from its id, which costs nothing to host, works offline, and looks
/// the same on every device and for every viewer because the id never changes.
///
/// It also has to be *stable*: deriving the colour from the display name would
/// re-shuffle everyone's avatar the moment someone renamed themselves, and
/// picking at random would give the same person a different colour on each
/// rebuild.
class UserAvatar extends StatelessWidget {
  /// Stable identity for this person — their user id.
  ///
  /// Falls back to the name when no id is to hand, which is still stable for
  /// as long as the name is.
  final String seed;

  /// Used for the initials only, never for the colour.
  final String displayName;
  final double size;

  const UserAvatar({
    super.key,
    required this.seed,
    required this.displayName,
    this.size = 40,
  });

  /// Colours with enough contrast against each other to tell two people apart
  /// at a glance, drawn from the app palette so avatars still look native.
  static const _palette = <Color>[
    AppColors.primary,
    AppColors.accent,
    AppColors.pink,
    AppColors.lime,
    AppColors.yellow,
    AppColors.success,
    AppColors.info,
    AppColors.primaryLight,
    AppColors.error,
    AppColors.accentLight,
  ];

  /// FNV-1a over the seed's bytes.
  ///
  /// Dart's `String.hashCode` is not guaranteed stable across releases or
  /// platforms, so an avatar keyed on it could change colour after an SDK
  /// upgrade or differ between a phone and the web build.
  static int _stableHash(String value) {
    var hash = 0x811c9dc5;
    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash;
  }

  static Color colorFor(String seed) =>
      _palette[_stableHash(seed) % _palette.length];

  /// Up to two initials: "Alex Dsouza" reads as AD, which distinguishes far
  /// more people than a single letter.
  static String initialsFor(String displayName) {
    final words = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first[0].toUpperCase();
    return (words.first[0] + words.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = colorFor(seed);

    // The palette mixes saturated and pastel tones, so the label colour is
    // chosen per background rather than fixed — white on lime is unreadable.
    final onColor = ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: NeoBrutalism.avatarDecoration(color: color, isDark: isDark),
      child: Text(
        initialsFor(displayName),
        style: TextStyle(
          color: onColor,
          fontWeight: FontWeight.w900,
          // Scales with the box so one widget serves the 36px member rows and
          // the 64px profile header alike.
          fontSize: size * 0.4,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
