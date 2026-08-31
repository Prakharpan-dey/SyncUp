import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neo_brutalism.dart';
import '../../domain/entities/attendance_session.dart';

class SessionCard extends StatelessWidget {
  final AttendanceSession session;
  final VoidCallback? onDelete;

  const SessionCard({
    super.key,
    required this.session,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPresent = session.isPresent;

    return Dismissible(
      key: Key(session.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.15),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
            width: NeoBrutalism.borderWidth,
          ),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: NeoBrutalism.cardDecoration(isDark: isDark),
        child: Row(
          children: [
            // Status indicator
            Container(
              width: 36,
              height: 36,
              decoration: NeoBrutalism.iconBoxDecoration(
                color: isPresent ? AppColors.success : AppColors.error,
                isDark: isDark,
              ),
              child: Icon(
                isPresent
                    ? Icons.check_rounded
                    : Icons.close_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat.yMMMd().format(session.sessionDate),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat.EEEE().format(session.sessionDate).toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            // Status chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: NeoBrutalism.chipDecoration(
                color: isPresent ? AppColors.success : AppColors.error,
                isDark: isDark,
              ),
              child: Text(
                isPresent ? 'PRESENT' : 'ABSENT',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
