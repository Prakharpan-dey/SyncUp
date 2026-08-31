import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neo_brutalism.dart';

class AttendancePercentageRing extends StatelessWidget {
  final double? percentage;
  final int thresholdPct;
  final double size;
  final double strokeWidth;

  const AttendancePercentageRing({
    super.key,
    required this.percentage,
    this.thresholdPct = 75,
    this.size = 120,
    this.strokeWidth = 10,
  });

  Color get _progressColor {
    if (percentage == null) return AppColors.textTertiary;
    if (percentage! >= thresholdPct) return AppColors.success;
    if (percentage! >= thresholdPct - 10) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trackColor = isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant;

    return Container(
      width: size + NeoBrutalism.borderWidth * 2 + NeoBrutalism.shadowOffsetValue,
      height: size + NeoBrutalism.borderWidth * 2 + NeoBrutalism.shadowOffsetValue,
      decoration: NeoBrutalism.cardDecoration(isDark: isDark),
      padding: EdgeInsets.all(size >= 100 ? 8 : 4),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(size - (size >= 100 ? 16 : 8), size - (size >= 100 ? 16 : 8)),
              painter: _RingPainter(
                progress: percentage != null ? percentage! / 100 : 0,
                progressColor: _progressColor,
                trackColor: trackColor,
                strokeWidth: strokeWidth,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: size >= 100 ? 12 : 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      percentage != null
                          ? '${percentage!.toStringAsFixed(size >= 100 ? 1 : 0)}%'
                          : '—',
                      style: size >= 100
                          ? Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: _progressColor,
                              )
                          : Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: _progressColor,
                              ),
                    ),
                  ),
                  if (percentage != null && size >= 100)
                    Text(
                      'ATTENDANCE',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                            letterSpacing: 1.2,
                          ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color trackColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.progressColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt;

      final sweepAngle = 2 * pi * progress.clamp(0.0, 1.0);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2, // Start from top
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.progressColor != progressColor;
}
