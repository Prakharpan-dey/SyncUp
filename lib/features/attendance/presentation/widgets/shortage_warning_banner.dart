import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

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
            'You must attend every remaining class — no absences allowed.',
      );
    }

    if (!isAboveThreshold && classesNeeded > 0) {
      return _buildBanner(
        context,
        icon: Icons.warning_amber_rounded,
        color: AppColors.warning,
        message:
            'You need to attend the next $classesNeeded class${classesNeeded == 1 ? '' : 'es'} to reach $thresholdPct%.',
      );
    }

    if (isAboveThreshold && safeToSkip > 0) {
      return _buildBanner(
        context,
        icon: Icons.check_circle_outline_rounded,
        color: AppColors.success,
        message:
            'You can safely skip the next $safeToSkip class${safeToSkip == 1 ? '' : 'es'}.',
      );
    }

    // At threshold exactly, can't skip any
    if (isAboveThreshold && safeToSkip == 0) {
      return _buildBanner(
        context,
        icon: Icons.info_outline_rounded,
        color: AppColors.info,
        message: 'You\'re right at $thresholdPct%. Don\'t skip any classes!',
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
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
