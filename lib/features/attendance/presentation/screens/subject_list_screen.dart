import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/auth/current_user.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neo_brutalism.dart';
import '../viewmodels/attendance_viewmodel.dart';

class SubjectListScreen extends ConsumerStatefulWidget {
  const SubjectListScreen({super.key});

  @override
  ConsumerState<SubjectListScreen> createState() => _SubjectListScreenState();
}

class _SubjectListScreenState extends ConsumerState<SubjectListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      ref
          .read(attendanceViewModelProvider.notifier)
          .loadSubjects(ref.read(currentUserIdProvider));
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(attendanceViewModelProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;
    final shadowColor = isDark ? AppColors.shadowDark : AppColors.border;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ATTENDANCE'),
      ),
      body: state.isLoading && state.subjects.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.subjects.isEmpty
              ? _buildEmptyState(context, isDark)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: state.subjects.length,
                  itemBuilder: (context, index) {
                    final subject = state.subjects[index];
                    final percentage =
                        state.attendancePercentage(subject.id);
                    final total = state.totalClasses(subject.id);
                    final attended = state.attendedClasses(subject.id);
                    final isAboveThreshold = percentage != null &&
                        percentage >= subject.thresholdPct;
                    final pctColor = percentage == null
                        ? AppColors.textTertiary
                        : isAboveThreshold
                            ? AppColors.success
                            : AppColors.error;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () =>
                            context.go('/attendance/${subject.id}'),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceDark
                                : AppColors.surface,
                            border: Border.all(
                                color: borderColor, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: shadowColor,
                                offset: const Offset(5, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Percentage box
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: pctColor,
                                  border: Border.all(
                                      color: borderColor, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: shadowColor,
                                      offset: const Offset(4, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Text(
                                        percentage != null
                                            ? '${percentage.round()}%'
                                            : '--',
                                        style: GoogleFonts.bigShoulders(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      subject.name.toUpperCase(),
                                      style: GoogleFonts.archivo(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      total == 0
                                          ? 'No classes logged'
                                          : '$attended / $total classes',
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
                              // Threshold chip
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  border: Border.all(
                                      color: borderColor, width: 2),
                                ),
                                child: Text(
                                  '${subject.thresholdPct}%',
                                  style: GoogleFonts.dmMono(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textTertiary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/attendance/new'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('ADD SUBJECT'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: NeoBrutalism.iconBoxDecoration(
                color: AppColors.primary,
                isDark: isDark,
              ),
              child: const Icon(
                Icons.school_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'NO SUBJECTS YET',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first subject to start\ntracking attendance.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/attendance/new'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('ADD SUBJECT'),
            ),
          ],
        ),
      ),
    );
  }
}
