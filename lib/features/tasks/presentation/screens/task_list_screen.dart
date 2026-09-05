import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/current_user.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neo_brutalism.dart';
import '../../../notifications/di/notification_providers.dart';
import '../../domain/entities/task.dart';
import '../viewmodels/task_viewmodel.dart';
import '../widgets/task_card.dart';
import '../widgets/stats_card.dart';
import '../widgets/streak_card.dart';
import '../../../../core/utils/streak.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      ref
          .read(taskViewModelProvider.notifier)
          .loadTasks(ref.read(currentUserIdProvider));
    });
  }

  @override
  Widget build(BuildContext context) {
    final taskState = ref.watch(taskViewModelProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TASKS'),
      ),
      body: taskState.isLoading && taskState.tasks.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : taskState.tasks.isEmpty
              ? _buildEmptyState(context, isDark)
              : _buildTaskList(taskState, isDark),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/tasks/new'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: NeoBrutalism.iconBoxDecoration(
              color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
              isDark: isDark,
            ),
            child: Icon(
              Icons.check_circle_outline_rounded,
              size: 40,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'NO TASKS YET',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Completes a task, then offers notifications the first time.
  ///
  /// The permission prompt is deliberately held until here rather than shown on
  /// cold launch: asking before the user has done anything is the reliable way
  /// to get it declined, and a denial is permanent on iOS.
  Future<void> _completeTask(Task task) async {
    await ref.read(taskViewModelProvider.notifier).toggleCompletion(task);
    if (!mounted) return;
    await ref
        .read(notificationPermissionHandlerProvider)
        .onFirstMeaningfulAction(context);
  }

  /// Overdue starts collapsed: it is the group that grows without bound when
  /// someone ignores a daily habit, and it is the least actionable.
  bool _overdueExpanded = false;

  List<Widget> _section(
    String label,
    List<Task> tasks,
    bool isDark, {
    bool collapsible = false,
  }) {
    if (tasks.isEmpty) return const [];
    final expanded = !collapsible || _overdueExpanded;

    return [
      const SizedBox(height: 8),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: GestureDetector(
          onTap: collapsible
              ? () => setState(() => _overdueExpanded = !_overdueExpanded)
              : null,
          child: Row(
            children: [
              Text(
                '$label (${tasks.length})',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: label == 'OVERDUE'
                          ? AppColors.error
                          : (isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary),
                    ),
              ),
              if (collapsible) ...[
                const SizedBox(width: 4),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: AppColors.error,
                ),
              ],
            ],
          ),
        ),
      ),
      if (expanded)
        ...tasks.map((task) => TaskCard(
              task: task,
              onTap: () => context.push('/tasks/${task.id}'),
              onToggle: () => _completeTask(task),
            )),
    ];
  }

  Widget _buildTaskList(TaskListState taskState, bool isDark) {
    final pendingTasks = taskState.tasks.where((t) => !t.isCompleted).toList();
    final completedTasks = taskState.tasks.where((t) => t.isCompleted).toList();

    // Grouped rather than one flat PENDING list. Repeating tasks materialise an
    // occurrence a day for a fortnight ahead, and missed ones are kept on
    // purpose, so a single list would put next Tuesday's medicine above this
    // morning's within a week of use.
    final now = DateTime.now();
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final overdue = pendingTasks.where((t) => t.isOverdue).toList()
      ..sort((a, b) => b.dueAt!.compareTo(a.dueAt!));
    final todayTasks = pendingTasks
        .where((t) =>
            !t.isOverdue && t.dueAt != null && !t.dueAt!.isAfter(endOfToday))
        .toList()
      ..sort((a, b) => a.dueAt!.compareTo(b.dueAt!));
    final upcoming = pendingTasks
        .where((t) => t.dueAt != null && t.dueAt!.isAfter(endOfToday))
        .toList()
      ..sort((a, b) => a.dueAt!.compareTo(b.dueAt!));
    final undated = pendingTasks.where((t) => t.dueAt == null).toList();

    return RefreshIndicator(
      onRefresh: () => ref
          .read(taskViewModelProvider.notifier)
          .loadTasks(ref.read(currentUserIdProvider)),
      child: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 100),
        children: [
          if (taskState.tasks.isNotEmpty) ...[
            StatsCard(
              totalTasks: taskState.tasks.length,
              completedTasks: taskState.completedCount,
              pendingTasks: taskState.pendingCount,
            ),
            const SizedBox(height: 8),
            StreakCard(
              currentStreak: currentStreak(taskState.tasks),
              // Was the current streak passed twice, so BEST could never
              // exceed today's run and fell whenever a day was missed.
              longestStreak: longestStreak(taskState.tasks),
            ),
            const SizedBox(height: 16),
          ],

          ..._section('OVERDUE', overdue, isDark, collapsible: true),
          ..._section('TODAY', todayTasks, isDark),
          ..._section('UPCOMING', upcoming, isDark),
          ..._section('NO DUE DATE', undated, isDark),

          if (completedTasks.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Text(
                'COMPLETED (${completedTasks.length})',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
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

}
