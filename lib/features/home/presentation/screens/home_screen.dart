import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/auth/current_user.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neo_brutalism.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../tasks/presentation/viewmodels/task_viewmodel.dart';
import '../../../tasks/domain/entities/task.dart';
import '../../../attendance/presentation/viewmodels/attendance_viewmodel.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final userId = ref.read(currentUserIdProvider);
      ref.read(taskViewModelProvider.notifier).loadTasks(userId);
      ref.read(attendanceViewModelProvider.notifier).loadSubjects(userId);
    });
  }

  int _calculateStreak(List<Task> tasks) {
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

  String _weekNumber() {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final dayOfYear = now.difference(startOfYear).inDays + 1;
    final weekNum = ((dayOfYear - now.weekday + 10) / 7).floor();
    return '$weekNum';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = ref.watch(authViewModelProvider);
    final taskState = ref.watch(taskViewModelProvider);
    final attendState = ref.watch(attendanceViewModelProvider);

    final displayName = authState.user?.displayName ?? 'There';
    final firstName = displayName.split(' ').first;
    final now = DateTime.now();
    final dateStr =
        '${DateFormat('EEE').format(now).toUpperCase()} ${now.day} ${DateFormat('MMM').format(now).toUpperCase()} · WEEK ${_weekNumber()}';
    final streak = _calculateStreak(taskState.tasks);
    final doneToday = taskState.completedCount;
    final pendingTasks =
        taskState.tasks.where((t) => !t.isCompleted).toList();
    final completedTasks =
        taskState.tasks.where((t) => t.isCompleted).toList();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            final userId = ref.read(currentUserIdProvider);
            await ref.read(taskViewModelProvider.notifier).loadTasks(userId);
            await ref
                .read(attendanceViewModelProvider.notifier)
                .loadSubjects(userId);
          },
          child: CustomScrollView(
            slivers: [
              // Header: greeting + avatar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hey,\n$firstName',
                              style: GoogleFonts.bigShoulders(
                                fontSize: 44,
                                fontWeight: FontWeight.w900,
                                height: 0.9,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dateStr,
                              style: GoogleFonts.dmMono(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1.2,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Square avatar
                      GestureDetector(
                        onTap: () => context.go('/profile'),
                        child: UserAvatar(
                          seed: authState.user?.id ?? firstName,
                          displayName: authState.user?.displayName ?? firstName,
                          size: 52,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Weekly recap entry point
              if (taskState.tasks.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: GestureDetector(
                      onTap: () => context.push('/weekly-recap'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.borderDark
                              : Colors.black,
                          border: Border.all(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.border,
                            width: NeoBrutalism.borderWidth,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? AppColors.shadowDark
                                  : AppColors.border,
                              offset: const Offset(4, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Text(
                              'WEEKLY RECAP READY',
                              style: GoogleFonts.dmMono(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1.0,
                                color: isDark
                                    ? Colors.black
                                    : Colors.white,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'VIEW →',
                              style: GoogleFonts.dmMono(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: isDark
                                    ? AppColors.primaryDark
                                    : AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // Stat boxes: STREAK + DONE TODAY
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: [
                      // Streak box (orange)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: NeoBrutalism.cardDecoration(
                            color: AppColors.warning,
                            isDark: isDark,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'STREAK',
                                style: GoogleFonts.dmMono(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '$streak',
                                      style: GoogleFonts.bigShoulders(
                                        fontSize: 40,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.black,
                                        height: 1.0,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' D',
                                      style: GoogleFonts.bigShoulders(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Done Today box (teal)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: NeoBrutalism.cardDecoration(
                            color: AppColors.accent,
                            isDark: isDark,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DONE TODAY',
                                style: GoogleFonts.dmMono(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '$doneToday',
                                      style: GoogleFonts.bigShoulders(
                                        fontSize: 40,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.black,
                                        height: 1.0,
                                      ),
                                    ),
                                    TextSpan(
                                      text: '/${taskState.tasks.length}',
                                      style: GoogleFonts.bigShoulders(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Today's Tasks section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Row(
                    children: [
                      Text(
                        'TASKS',
                        style: GoogleFonts.dmMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.2,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'COUNTS ONLY',
                        style: GoogleFonts.dmMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Task list (pending first, then completed)
              if (taskState.isLoading && taskState.tasks.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (taskState.tasks.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration:
                          NeoBrutalism.flatCardDecoration(isDark: isDark),
                      child: Column(
                        children: [
                          Icon(
                            Icons.task_alt_rounded,
                            size: 36,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textTertiary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'NO TASKS FOR TODAY',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () => context.push('/tasks/new'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: NeoBrutalism.chipDecoration(
                                color: AppColors.primary,
                                isDark: isDark,
                              ),
                              child: Text(
                                'ADD TASK',
                                style: GoogleFonts.dmMono(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList.builder(
                    itemCount:
                        pendingTasks.length + completedTasks.length,
                    itemBuilder: (context, index) {
                      final task = index < pendingTasks.length
                          ? pendingTasks[index]
                          : completedTasks[
                              index - pendingTasks.length];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _HomeTaskItem(
                          task: task,
                          isDark: isDark,
                          onToggle: () => ref
                              .read(taskViewModelProvider.notifier)
                              .toggleCompletion(task),
                          onTap: () =>
                              context.push('/tasks/${task.id}'),
                        ),
                      );
                    },
                  ),
                ),

              // Attendance Quick Look
              if (attendState.subjects.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Row(
                      children: [
                        Text(
                          'ATTENDANCE',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => context.go('/attendance'),
                          child: Text(
                            'VIEW ALL',
                            style: GoogleFonts.dmMono(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  sliver: SliverList.builder(
                    itemCount: attendState.subjects.length,
                    itemBuilder: (context, index) {
                      final subject = attendState.subjects[index];
                      final pct =
                          attendState.attendancePercentage(subject.id);
                      final total =
                          attendState.totalClasses(subject.id);
                      final attended =
                          attendState.attendedClasses(subject.id);
                      final isBelowThreshold = pct != null &&
                          pct < subject.thresholdPct;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          onTap: () => context.push(
                              '/attendance/${subject.id}'),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: NeoBrutalism.cardDecoration(
                                isDark: isDark),
                            child: Row(
                              children: [
                                // Percentage indicator
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration:
                                      NeoBrutalism.iconBoxDecoration(
                                    color: isBelowThreshold
                                        ? AppColors.error
                                        : AppColors.success,
                                    isDark: isDark,
                                  ),
                                  child: Center(
                                    child: Text(
                                      pct != null
                                          ? '${pct.round()}%'
                                          : '--',
                                      style: GoogleFonts.dmMono(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        subject.name.toUpperCase(),
                                        style: theme
                                            .textTheme.bodyMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                        maxLines: 1,
                                        overflow:
                                            TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$attended / $total CLASSES',
                                        style: GoogleFonts.dmMono(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: isDark
                                              ? AppColors
                                                  .textSecondaryDark
                                              : AppColors
                                                  .textSecondary,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isBelowThreshold)
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4),
                                    decoration:
                                        NeoBrutalism.chipDecoration(
                                      color: AppColors.error,
                                      isDark: isDark,
                                    ),
                                    child: Text(
                                      'LOW',
                                      style: GoogleFonts.dmMono(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],

              // Bottom padding when no attendance
              if (attendState.subjects.isEmpty)
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
            ],
          ),
        ),
      ),
    );
  }

}

class _HomeTaskItem extends StatelessWidget {
  final Task task;
  final bool isDark;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  const _HomeTaskItem({
    required this.task,
    required this.isDark,
    required this.onToggle,
    required this.onTap,
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

  String _formatMeta() {
    final parts = <String>[];
    if (task.dueDate != null) {
      final due = task.dueDate!;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dueDay = DateTime(due.year, due.month, due.day);
      final diff = dueDay.difference(today).inDays;
      if (diff == 0) {
        parts.add(
            'DUE ${due.hour.toString().padLeft(2, '0')}:${due.minute.toString().padLeft(2, '0')}');
      } else if (diff == 1) {
        parts.add('DUE TOMORROW');
      } else if (diff < 0) {
        parts.add('OVERDUE');
      } else if (diff <= 7) {
        parts.add(
            'DUE ${DateFormat('EEE').format(due).toUpperCase()}');
      } else {
        parts.add(
            'DUE ${due.day}/${due.month}');
      }
    } else {
      parts.add('NO DUE DATE');
    }
    if (task.tags.isNotEmpty) {
      parts.add(task.tags.first.toUpperCase());
    }
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = task.isCompleted;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: NeoBrutalism.cardDecoration(isDark: isDark),
        child: Row(
          children: [
            GestureDetector(
              onTap: onToggle,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.backgroundDark : Colors.white,
                  border: Border.all(
                    color:
                        isDark ? AppColors.borderDark : AppColors.border,
                    width: NeoBrutalism.borderWidth,
                  ),
                ),
                child: isCompleted
                    ? Center(
                        child: Text(
                          '×',
                          style: GoogleFonts.bigShoulders(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.success,
                            height: 1.0,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      decoration:
                          isCompleted ? TextDecoration.lineThrough : null,
                      color: isCompleted
                          ? (isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary)
                          : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _formatMeta(),
                    style: GoogleFonts.dmMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: _priorityColor(task.priority),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.border,
                  width: NeoBrutalism.borderWidthSmall,
                ),
              ),
              child: Text(
                _priorityLabel(task.priority),
                style: GoogleFonts.dmMono(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
