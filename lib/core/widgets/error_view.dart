import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/neo_brutalism.dart';

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  const ErrorView({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline_rounded,
  });

  const ErrorView.network({super.key, this.onRetry})
      : message = 'Cannot connect to the server.\nCheck your internet connection.',
        icon = Icons.wifi_off_rounded;

  const ErrorView.server({super.key, this.onRetry})
      : message = 'Something went wrong.\nPlease try again later.',
        icon = Icons.cloud_off_rounded;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: NeoBrutalism.iconBoxDecoration(
                isDark: isDark,
                color: AppColors.error.withValues(alpha: 0.2),
              ),
              child: Icon(
                icon,
                size: 40,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
