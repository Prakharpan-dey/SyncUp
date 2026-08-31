import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neo_brutalism.dart';
import '../../domain/entities/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onToggle,
  });

  Color _priorityColor(TaskPriority priority) {
    return switch (priority) {
      TaskPriority.high => AppColors.error,
      TaskPriority.medium => AppColors.warning,
      TaskPriority.low => AppColors.success,
    };
  }

  String _priorityLabel(TaskPriority priority) {
    return switch (priority) {
      TaskPriority.high => 'HIGH',
      TaskPriority.medium => 'MED',
      TaskPriority.low => 'LOW',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompleted = task.isCompleted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: NeoBrutalism.cardDecoration(isDark: isDark),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Completion checkbox — square, neobrutalist
              GestureDetector(
                onTap: onToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.primary
                        : Colors.transparent,
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.border,
                      width: NeoBrutalism.borderWidthSmall,
                    ),
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 12),

              // Title + due date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        decoration:
                            isCompleted ? TextDecoration.lineThrough : null,
                        color: isCompleted
                            ? (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary)
                            : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (task.dueDate != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        _formatDueDate(task.dueDate!),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _isDueOverdue(task.dueDate!) && !isCompleted
                              ? AppColors.error
                              : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Priority badge — chip style
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: NeoBrutalism.chipDecoration(
                  color: _priorityColor(task.priority),
                  isDark: isDark,
                ),
                child: Text(
                  _priorityLabel(task.priority),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(date.year, date.month, date.day);
    final diff = due.difference(today).inDays;
    if (diff == 0) return 'Due today';
    if (diff == 1) return 'Due tomorrow';
    if (diff == -1) return 'Due yesterday';
    if (diff < 0) return 'Overdue by ${-diff}d';
    if (diff <= 7) return 'Due in ${diff}d';
    return '${date.day}/${date.month}/${date.year}';
  }

  bool _isDueOverdue(DateTime date) {
    return date.isBefore(DateTime.now());
  }
}
