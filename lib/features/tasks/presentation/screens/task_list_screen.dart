import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../viewmodels/task_viewmodel.dart';
import '../widgets/task_card.dart';
import '../widgets/stats_card.dart';
import '../widgets/streak_card.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  @override
  void initState() {
    super.initState();
    // Load tasks on screen init — using a placeholder userId until auth is wired
    Future.microtask(() {
      ref.read(taskViewModelProvider.notifier).loadTasks('local-user');
    });
  }

  @override
  Widget build(BuildContext context) {
    final taskState = ref.watch(taskViewModelProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
      ),
      body: taskState.isLoading && taskState.tasks.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : taskState.tasks.isEmpty
              ? _buildEmptyState(theme)
              : _buildTaskList(taskState, theme),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/tasks/new'),
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 80,
            color: theme.colorScheme.outline.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Nothing here. Add a task.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to get started',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(TaskListState taskState, ThemeData theme) {
    final pendingTasks = taskState.tasks.where((t) => !t.isCompleted).toList();
    final completedTasks = taskState.tasks.where((t) => t.isCompleted).toList();

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(taskViewModelProvider.notifier).loadTasks('local-user'),
      child: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 100),
        children: [
          // Stats card
          if (taskState.tasks.isNotEmpty) ...[
            StatsCard(
              totalTasks: taskState.tasks.length,
              completedTasks: taskState.completedCount,
              pendingTasks: taskState.pendingCount,
            ),
            const SizedBox(height: 8),
            StreakCard(
              currentStreak: _calculateStreak(taskState.tasks),
              longestStreak: _calculateStreak(taskState.tasks),
            ),
            const SizedBox(height: 16),
          ],

          // Pending tasks
          if (pendingTasks.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Text(
                'Pending (${pendingTasks.length})',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
            ...pendingTasks.map((task) => TaskCard(
                  task: task,
                  onTap: () => context.push('/tasks/${task.id}'),
                  onToggle: () => ref
                      .read(taskViewModelProvider.notifier)
                      .toggleCompletion(task),
                )),
          ],

          // Completed tasks
          if (completedTasks.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Text(
                'Completed (${completedTasks.length})',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
            ...completedTasks.map((task) => TaskCard(
                  task: task,
                  onTap: () => context.push('/tasks/${task.id}'),
                  onToggle: () => ref
                      .read(taskViewModelProvider.notifier)
                      .toggleCompletion(task),
                )),
          ],
        ],
      ),
    );
  }

  int _calculateStreak(List tasks) {
    // Simple streak: count consecutive days with at least one completed task
    if (tasks.isEmpty) return 0;
    final completedDates = tasks
        .where((t) => t.isCompleted && t.completedAt != null)
        .map((t) => DateTime(
            t.completedAt!.year, t.completedAt!.month, t.completedAt!.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (completedDates.isEmpty) return 0;

    int streak = 0;
    var check = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);
    for (final date in completedDates) {
      if (date == check) {
        streak++;
        check = check.subtract(const Duration(days: 1));
      } else if (date.isBefore(check)) {
        break;
      }
    }
    return streak;
  }
}
