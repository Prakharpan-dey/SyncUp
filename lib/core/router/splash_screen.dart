import 'package:flutter/material.dart';

import '../widgets/brand_logo.dart';

/// Shown at `/` while the stored session is being restored.
///
/// Without this the app would boot straight onto sign-in and then jump away
/// once auth resolved, flashing a login form at users who are already signed in
/// (or using the app as a guest).
///
/// It continues the native splash exactly: same ground colour and the same
/// symbol at the same size (140 dp, the native image is 560 px at 4x), so the
/// handoff from the OS to Flutter is invisible.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? BrandColors.ink : BrandColors.paper,
      body: const Center(child: SyncUpSymbol(height: 140)),
    );
  }
}
