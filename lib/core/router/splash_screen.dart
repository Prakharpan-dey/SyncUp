import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/neo_brutalism.dart';

/// Shown at `/` while the stored session is being restored.
///
/// Without this the app would boot straight onto sign-in and then jump away
/// once auth resolved, flashing a login form at users who are already signed in
/// (or using the app as a guest).
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.background,
      body: Center(
        child: Container(
          width: 84,
          height: 84,
          decoration: NeoBrutalism.iconBoxDecoration(
            color: AppColors.primary,
            isDark: isDark,
          ),
          child: const Center(
            child: Text(
              'S',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 40,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
