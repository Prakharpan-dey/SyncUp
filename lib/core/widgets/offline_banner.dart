import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../di/core_providers.dart';
import '../theme/app_colors.dart';

/// Animated offline banner that slides down when connectivity is lost
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityServiceProvider);
    final isOffline = !connectivity.isOnline;

    return AnimatedSlide(
      offset: isOffline ? Offset.zero : const Offset(0, -1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: AnimatedOpacity(
        opacity: isOffline ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.warning.withValues(alpha: 0.95),
                AppColors.warning,
              ],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_off_rounded,
                    color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  'You are offline',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
