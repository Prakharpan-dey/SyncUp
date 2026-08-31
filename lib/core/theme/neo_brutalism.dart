import 'package:flutter/material.dart';
import 'app_colors.dart';

class NeoBrutalism {
  static const double borderWidth = 3.0;
  static const double borderWidthSmall = 2.0;
  static const double shadowOffsetValue = 5.0;
  static const Offset shadowOffset = Offset(shadowOffsetValue, shadowOffsetValue);
  static const double radius = 0;

  static Color _borderColor(bool isDark) =>
      isDark ? AppColors.borderDark : AppColors.border;

  static Color _shadowColor(bool isDark) =>
      isDark ? AppColors.shadowDark : AppColors.border;

  static BoxDecoration cardDecoration({
    Color? color,
    bool isDark = false,
  }) {
    return BoxDecoration(
      color: color ?? (isDark ? AppColors.surfaceDark : AppColors.surface),
      border: Border.all(
        color: _borderColor(isDark),
        width: borderWidth,
      ),
      boxShadow: [
        BoxShadow(
          color: _shadowColor(isDark),
          offset: shadowOffset,
        ),
      ],
    );
  }

  static BoxDecoration flatCardDecoration({
    Color? color,
    bool isDark = false,
  }) {
    return BoxDecoration(
      color: color ?? (isDark ? AppColors.surfaceDark : AppColors.surface),
      border: Border.all(
        color: _borderColor(isDark),
        width: borderWidth,
      ),
    );
  }

  static BoxDecoration iconBoxDecoration({
    required Color color,
    bool isDark = false,
  }) {
    return BoxDecoration(
      color: color,
      border: Border.all(
        color: _borderColor(isDark),
        width: borderWidth,
      ),
      boxShadow: [
        BoxShadow(
          color: _shadowColor(isDark),
          offset: const Offset(4, 4),
        ),
      ],
    );
  }

  static BoxDecoration chipDecoration({
    required Color color,
    bool isDark = false,
  }) {
    return BoxDecoration(
      color: color,
      border: Border.all(
        color: _borderColor(isDark),
        width: borderWidthSmall,
      ),
    );
  }

  static BoxDecoration avatarDecoration({
    Color? color,
    bool isDark = false,
  }) {
    return BoxDecoration(
      color: color ?? AppColors.primary,
      border: Border.all(
        color: _borderColor(isDark),
        width: borderWidth,
      ),
      boxShadow: [
        BoxShadow(
          color: _shadowColor(isDark),
          offset: const Offset(4, 4),
        ),
      ],
    );
  }

  static BoxDecoration bannerDecoration({
    required Color color,
    bool isDark = false,
  }) {
    return BoxDecoration(
      color: color,
      border: Border.all(
        color: _borderColor(isDark),
        width: borderWidth,
      ),
      boxShadow: [
        BoxShadow(
          color: _shadowColor(isDark),
          offset: shadowOffset,
        ),
      ],
    );
  }

  static BoxDecoration selectedDecoration({
    required Color color,
    bool isDark = false,
  }) {
    return BoxDecoration(
      color: color,
      border: Border.all(
        color: _borderColor(isDark),
        width: borderWidth,
      ),
      boxShadow: [
        BoxShadow(
          color: _shadowColor(isDark),
          offset: const Offset(6, 6),
        ),
      ],
    );
  }

  static BoxDecoration unselectedDecoration({
    Color? color,
    bool isDark = false,
  }) {
    return BoxDecoration(
      color: color ?? (isDark ? AppColors.surfaceDark : AppColors.surface),
      border: Border.all(
        color: _borderColor(isDark),
        width: borderWidth,
      ),
    );
  }
}
