import 'package:flutter/material.dart';

/// The SyncUp palette, matched to the logo: cobalt and acid lime on warm
/// off-white, with ink for text, borders and hard shadows.
class AppColors {
  // Primary: Cobalt Blue, the logo's top block.
  static const primary = Color(0xFF4169FF);
  static const primaryLight = Color(0xFF8DA6FF);
  static const primaryDark = Color(0xFF2A4FD6);

  // Accent: Acid Lime, the logo's bottom block. Light enough that white on it
  // is unreadable: put [onAccent] (ink) on it, never white.
  static const accent = Color(0xFFD7FF38);
  static const accentLight = Color(0xFFECFF9C);
  static const onAccent = Color(0xFF171717);

  // Neobrutalism feature colors
  static const yellow = Color(0xFFFDAA5D);
  static const pink = Color(0xFFFF90BC);
  static const lime = Color(0xFFC8F77E);

  // Semantic
  static const success = Color(0xFF00B894);
  static const warning = Color(0xFFFDAA5D);
  static const error = Color(0xFFFF6B6B);
  static const info = Color(0xFF74C0FC);

  // Neutral (Light): Warm Off-White ground, Ink Black lines and text.
  static const background = Color(0xFFF7F6F0);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFEFEEE7);
  static const textPrimary = Color(0xFF171717);
  static const textSecondary = Color(0xFF555555);
  static const textTertiary = Color(0xFF888888);
  static const border = Color(0xFF171717);

  // Neutral (Dark) — inverted neobrutalism, on the logo's ink.
  static const backgroundDark = Color(0xFF171717);
  static const surfaceDark = Color(0xFF222222);
  static const surfaceVariantDark = Color(0xFF171717);
  static const textPrimaryDark = Color(0xFFF7F6F0);
  static const textSecondaryDark = Color(0xFF8A8A8A);
  static const borderDark = Color(0xFFF7F6F0);
  static const shadowDark = Color(0xFFF7F6F0);

  /// Ink or white, whichever reads on [background]. For fills chosen at
  /// runtime (setting tiles, notification icons) where the colour can be lime.
  static Color on(Color background) =>
      ThemeData.estimateBrightnessForColor(background) == Brightness.dark
          ? Colors.white
          : onAccent;
}
