import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neo_brutalism.dart';

/// Error banner shared by the auth screens.
///
/// This markup was previously copy-pasted into sign-in and sign-up; extracting
/// it keeps the new verification, forgot-password and reset screens visually
/// identical without a fourth and fifth copy.
class AuthErrorBanner extends StatelessWidget {
  final String message;

  const AuthErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: NeoBrutalism.bannerDecoration(
        color: AppColors.error,
        isDark: isDark,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, size: 18, color: Colors.black),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
