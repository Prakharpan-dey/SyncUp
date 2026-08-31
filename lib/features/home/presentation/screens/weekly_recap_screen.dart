import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';

import '../../../tasks/presentation/viewmodels/task_viewmodel.dart';
import '../../../tasks/domain/entities/task.dart';
import '../../../attendance/presentation/viewmodels/attendance_viewmodel.dart';

class WeeklyRecapScreen extends ConsumerWidget {
  const WeeklyRecapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskState = ref.watch(taskViewModelProvider);
    final attendState = ref.watch(attendanceViewModelProvider);
    final now = DateTime.now();

    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    final weekNum = _weekNumber(now);
    final dateRange =
        '${weekStart.day}–${weekEnd.day} ${DateFormat('MMM').format(weekEnd).toUpperCase()}';

    final weekTasks = taskState.tasks;
    final completedTasks =
        weekTasks.where((t) => t.isCompleted).toList();
    final daysActive = _daysActive(completedTasks);
    final totalCompleted = completedTasks.length;

    final overallAttendance = _overallAttendance(attendState);

    final dailyTaskCounts = _dailyTaskCounts(completedTasks, weekStart);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : Colors.black;
    final borderColor = isDark ? AppColors.borderDark : Colors.white;
    final textColor = isDark ? AppColors.textPrimaryDark : Colors.white;
    final secondaryText = isDark ? AppColors.textSecondaryDark : const Color(0xFF888888);
    final panelColor = isDark ? AppColors.surfaceDark : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Week header
                    Text(
                      'WEEK $weekNum · $dateRange',
                      style: GoogleFonts.dmMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.2,
                        color: secondaryText,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Big headline
                    Text(
                      'You showed\nup $daysActive of 7\ndays',
                      style: GoogleFonts.bigShoulders(
                        fontSize: 52,
                        fontWeight: FontWeight.w900,
                        height: 0.86,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 3 stat boxes
                    Row(
                      children: [
                        _RecapStat(
                          label: 'FOCUS',
                          value: '${_estimatedHours(completedTasks)}H',
                          color: AppColors.accent,
                          borderColor: borderColor,
                          textColor: Colors.black,
                        ),
                        const SizedBox(width: 9),
                        _RecapStat(
                          label: 'TASKS',
                          value: '$totalCompleted',
                          color: AppColors.warning,
                          borderColor: borderColor,
                          textColor: Colors.black,
                        ),
                        const SizedBox(width: 9),
                        _RecapStat(
                          label: 'CLASSES',
                          value: overallAttendance != null
                              ? '${overallAttendance.round()}%'
                              : '--',
                          color: isDark ? AppColors.surfaceDark : Colors.white,
                          borderColor: borderColor,
                          textColor: isDark ? textColor : Colors.black,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Hours by day bar chart
                    Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: borderColor, width: 3),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TASKS BY DAY',
                            style: GoogleFonts.dmMono(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.0,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 110,
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.end,
                              children: List.generate(7, (i) {
                                final count = dailyTaskCounts[i];
                                final maxCount =
                                    dailyTaskCounts.reduce(
                                        (a, b) => a > b ? a : b);
                                final fraction = maxCount > 0
                                    ? count / maxCount
                                    : 0.0;
                                final isToday =
                                    i == now.weekday - 1;
                                return Expanded(
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 3),
                                    child: Container(
                                      height: fraction > 0
                                          ? 110 * fraction
                                          : 0,
                                      decoration: BoxDecoration(
                                        color: count == 0
                                            ? const Color(
                                                0xFF333333)
                                            : isToday
                                                ? AppColors.accent
                                                : AppColors.primary,
                                        border: Border.all(
                                          color: count == 0
                                              ? const Color(
                                                  0xFF555555)
                                              : borderColor,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                          const SizedBox(height: 7),
                          Row(
                            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                                .map((d) => Expanded(
                                      child: Text(
                                        d,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.dmMono(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w400,
                                          color: secondaryText,
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Attendance breakdown
                    if (attendState.subjects.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: borderColor, width: 3),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ATTENDANCE BREAKDOWN',
                              style: GoogleFonts.dmMono(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1.0,
                                color: secondaryText,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ...attendState.subjects.map((s) {
                              final pct = attendState
                                  .attendancePercentage(s.id);
                              return Padding(
                                padding: const EdgeInsets.only(
                                    bottom: 4),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        s.name.toUpperCase(),
                                        style: GoogleFonts.archivo(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: textColor,
                                        ),
                                        maxLines: 1,
                                        overflow:
                                            TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      pct != null
                                          ? '${pct.round()}%'
                                          : '--',
                                      style: GoogleFonts.dmMono(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: pct != null &&
                                                pct <
                                                    s.thresholdPct
                                            ? AppColors.error
                                            : AppColors.success,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Bottom buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Sharing coming soon!')),
                        );
                      },
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          border: Border.all(
                              color: borderColor, width: 3),
                        ),
                        child: Center(
                          child: Text(
                            'SHARE RECAP',
                            style: GoogleFonts.bigShoulders(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: panelColor,
                          border: Border.all(
                              color: borderColor, width: 3),
                        ),
                        child: Center(
                          child: Text(
                            'SKIP',
                            style: GoogleFonts.bigShoulders(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),
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

  int _weekNumber(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final dayOfYear = date.difference(startOfYear).inDays + 1;
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  int _daysActive(List<Task> completed) {
    final days = completed
        .where((t) => t.completedAt != null)
        .map((t) => DateTime(t.completedAt!.year, t.completedAt!.month,
            t.completedAt!.day))
        .toSet();
    return days.length.clamp(0, 7);
  }

  int _estimatedHours(List<Task> completed) {
    return (completed.length * 0.5).ceil().clamp(0, 99);
  }

  double? _overallAttendance(AttendanceState state) {
    if (state.subjects.isEmpty) return null;
    int totalAttended = 0;
    int totalClasses = 0;
    for (final s in state.subjects) {
      totalAttended += state.attendedClasses(s.id);
      totalClasses += state.totalClasses(s.id);
    }
    if (totalClasses == 0) return null;
    return (totalAttended / totalClasses) * 100;
  }

  List<int> _dailyTaskCounts(List<Task> completed, DateTime weekStart) {
    final counts = List.filled(7, 0);
    for (final task in completed) {
      if (task.completedAt == null) continue;
      final diff = DateTime(task.completedAt!.year,
              task.completedAt!.month, task.completedAt!.day)
          .difference(
              DateTime(weekStart.year, weekStart.month, weekStart.day))
          .inDays;
      if (diff >= 0 && diff < 7) {
        counts[diff]++;
      }
    }
    return counts;
  }
}

class _RecapStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color borderColor;
  final Color textColor;

  const _RecapStat({
    required this.label,
    required this.value,
    required this.color,
    required this.borderColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: borderColor, width: 3),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.dmMono(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.bigShoulders(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                height: 1.0,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
