import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neo_brutalism.dart';

class ShortageWarningBanner extends StatelessWidget {
  final int classesNeeded;
  final int safeToSkip;
  final int thresholdPct;
  final double? percentage;

  const ShortageWarningBanner({
    super.key,
    required this.classesNeeded,
    required this.safeToSkip,
    required this.thresholdPct,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    // No classes logged yet
    if (percentage == null) return const SizedBox.shrink();

    final isAboveThreshold = percentage! >= thresholdPct;

    // θ = 100% and absences exist → impossible case
    if (classesNeeded == -1) {
      return _buildBanner(
        context,
        icon: Icons.error_outline_rounded,
        color: AppColors.error,
        message:
            'YOU MUST ATTEND EVERY REMAINING CLASS — NO ABSENCES ALLOWED.',
      );
    }

    if (!isAboveThreshold && classesNeeded > 0) {
      return _buildBanner(
        context,
        icon: Icons.warning_amber_rounded,
        color: AppColors.warning,
        message:
            'YOU NEED TO ATTEND THE NEXT $classesNeeded CLASS${classesNeeded == 1 ? '' : 'ES'} TO REACH $thresholdPct%.',
      );
    }

    if (isAboveThreshold && safeToSkip > 0) {
      return _buildBanner(
        context,
        icon: Icons.check_circle_outline_rounded,
        color: AppColors.success,
        message:
            'YOU CAN SAFELY SKIP THE NEXT $safeToSkip CLASS${safeToSkip == 1 ? '' : 'ES'}.',
      );
    }

    // At threshold exactly, can't skip any
    if (isAboveThreshold && safeToSkip == 0) {
      return _buildBanner(
        context,
        icon: Icons.info_outline_rounded,
        color: AppColors.info,
        message: 'YOU\'RE RIGHT AT $thresholdPct%. DON\'T SKIP ANY CLASSES!',
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildBanner(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String message,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: NeoBrutalism.bannerDecoration(color: color, isDark: isDark),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
