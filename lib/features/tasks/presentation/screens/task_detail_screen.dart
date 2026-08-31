import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neo_brutalism.dart';
import '../../domain/entities/task.dart';
import '../viewmodels/task_viewmodel.dart';

class TaskDetailScreen extends ConsumerWidget {
  final String taskId;
  const TaskDetailScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskState = ref.watch(taskViewModelProvider);
    final task = taskState.tasks.where((t) => t.id == taskId).firstOrNull;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (task == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Task not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('TASK DETAILS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('DELETE TASK'),
                  content: const Text(
                      'Are you sure you want to delete this task?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('CANCEL'),
                    ),
                    TextButton(
                      onPressed: () {
                        ref
                            .read(taskViewModelProvider.notifier)
                            .deleteTask(task.id);
                        Navigator.pop(ctx);
                        context.pop();
                      },
                      child: const Text('DELETE',
                          style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: NeoBrutalism.chipDecoration(
                    color: task.isCompleted ? AppColors.success : AppColors.warning,
                    isDark: isDark,
                  ),
                  child: Text(
                    task.isCompleted ? 'COMPLETED' : 'PENDING',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: NeoBrutalism.chipDecoration(
                    color: _priorityColor(task.priority),
                    isDark: isDark,
                  ),
                  child: Text(
                    _priorityLabel(task.priority),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Text(
              task.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                decoration:
                    task.isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),

            if (task.description != null &&
                task.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                task.description!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
              ),
            ],

            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              height: 2,
              color: isDark ? AppColors.borderDark : AppColors.border,
            ),
            const SizedBox(height: 16),

            _buildDetailRow(
              context: context,
              isDark: isDark,
              icon: Icons.calendar_today_rounded,
              label: 'DUE DATE',
              value: task.dueDate != null
                  ? '${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}'
                  : 'No due date',
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              context: context,
              isDark: isDark,
              icon: Icons.access_time_rounded,
              label: 'CREATED',
              value:
                  '${task.createdAt.day}/${task.createdAt.month}/${task.createdAt.year}',
            ),
            if (task.completedAt != null) ...[
              const SizedBox(height: 12),
              _buildDetailRow(
                context: context,
                isDark: isDark,
                icon: Icons.check_circle_rounded,
                label: 'COMPLETED',
                value:
                    '${task.completedAt!.day}/${task.completedAt!.month}/${task.completedAt!.year}',
              ),
            ],
            if (task.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildDetailRow(
                context: context,
                isDark: isDark,
                icon: Icons.label_outline_rounded,
                label: 'TAGS',
                value: task.tags.join(', '),
              ),
            ],

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ref
                      .read(taskViewModelProvider.notifier)
                      .toggleCompletion(task);
                },
                icon: Icon(
                  task.isCompleted
                      ? Icons.undo_rounded
                      : Icons.check_circle_rounded,
                ),
                label: Text(
                  task.isCompleted
                      ? 'MARK AS PENDING'
                      : 'MARK AS COMPLETE',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: task.isCompleted
                      ? (isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant)
                      : AppColors.success,
                  foregroundColor: task.isCompleted
                      ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)
                      : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

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
      TaskPriority.medium => 'MEDIUM',
      TaskPriority.low => 'LOW',
    };
  }
}
