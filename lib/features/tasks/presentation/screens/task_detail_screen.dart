import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/task.dart';
import '../viewmodels/task_viewmodel.dart';

class TaskDetailScreen extends ConsumerWidget {
  final String taskId;
  const TaskDetailScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskState = ref.watch(taskViewModelProvider);
    final task = taskState.tasks.where((t) => t.id == taskId).firstOrNull;
    final theme = Theme.of(context);

    if (task == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Task not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Task'),
                  content: const Text(
                      'Are you sure you want to delete this task?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        ref
                            .read(taskViewModelProvider.notifier)
                            .deleteTask(task.id);
                        Navigator.pop(ctx);
                        context.pop();
                      },
                      child: Text(
                        'Delete',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
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
            // Status & Priority row
            Row(
              children: [
                _buildChip(
                  label: task.isCompleted ? 'Completed' : 'Pending',
                  color: task.isCompleted
                      ? const Color(0xFF00B894)
                      : const Color(0xFFFDAA5D),
                  theme: theme,
                ),
                const SizedBox(width: 8),
                _buildChip(
                  label: _priorityLabel(task.priority),
                  color: _priorityColor(task.priority),
                  theme: theme,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              task.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                decoration:
                    task.isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),

            // Description
            if (task.description != null &&
                task.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                task.description!,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Details
            _buildDetailRow(
              icon: Icons.calendar_today_rounded,
              label: 'Due Date',
              value: task.dueDate != null
                  ? '${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}'
                  : 'No due date',
              theme: theme,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              icon: Icons.access_time_rounded,
              label: 'Created',
              value:
                  '${task.createdAt.day}/${task.createdAt.month}/${task.createdAt.year}',
              theme: theme,
            ),
            if (task.completedAt != null) ...[
              const SizedBox(height: 12),
              _buildDetailRow(
                icon: Icons.check_circle_rounded,
                label: 'Completed',
                value:
                    '${task.completedAt!.day}/${task.completedAt!.month}/${task.completedAt!.year}',
                theme: theme,
              ),
            ],
            if (task.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildDetailRow(
                icon: Icons.label_outline_rounded,
                label: 'Tags',
                value: task.tags.join(', '),
                theme: theme,
              ),
            ],

            const SizedBox(height: 32),

            // Toggle completion button
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
                      ? 'Mark as Pending'
                      : 'Mark as Complete',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: task.isCompleted
                      ? theme.colorScheme.surfaceContainerHighest
                      : const Color(0xFF00B894),
                  foregroundColor: task.isCompleted
                      ? theme.colorScheme.onSurface
                      : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required Color color,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.outline),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Color _priorityColor(TaskPriority priority) {
    return switch (priority) {
      TaskPriority.high => const Color(0xFFFF6B6B),
      TaskPriority.medium => const Color(0xFFFDAA5D),
      TaskPriority.low => const Color(0xFF00B894),
    };
  }

  String _priorityLabel(TaskPriority priority) {
    return switch (priority) {
      TaskPriority.high => 'High',
      TaskPriority.medium => 'Medium',
      TaskPriority.low => 'Low',
    };
  }
}
