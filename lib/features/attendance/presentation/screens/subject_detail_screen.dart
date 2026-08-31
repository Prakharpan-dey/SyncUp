import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/neo_brutalism.dart';
import '../../domain/entities/attendance_session.dart';
import '../viewmodels/attendance_viewmodel.dart';

class SubjectDetailScreen extends ConsumerStatefulWidget {
  final String subjectId;
  const SubjectDetailScreen({super.key, required this.subjectId});

  @override
  ConsumerState<SubjectDetailScreen> createState() =>
      _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends ConsumerState<SubjectDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(attendanceViewModelProvider.notifier)
          .loadSessions(widget.subjectId);
    });
  }

  void _confirmDeleteSubject() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('DELETE SUBJECT'),
        content: const Text(
            'This will delete the subject and all its attendance records. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(attendanceViewModelProvider.notifier)
                  .deleteSubject(widget.subjectId);
              Navigator.pop(ctx);
              context.go('/attendance');
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(attendanceViewModelProvider);
    final vm = ref.read(attendanceViewModelProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;
    final shadowColor = isDark ? AppColors.shadowDark : AppColors.border;

    final subject =
        state.subjects.where((s) => s.id == widget.subjectId).firstOrNull;

    if (subject == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Subject not found')),
      );
    }

    final percentage = state.attendancePercentage(subject.id);
    final total = state.totalClasses(subject.id);
    final attended = state.attendedClasses(subject.id);
    final safeToSkip = vm.safeToSkip(subject.id);
    final classesNeeded = vm.classesNeeded(subject.id);

    final sessions =
        state.sessions.where((s) => s.subjectId == subject.id).toList()
          ..sort((a, b) => b.sessionDate.compareTo(a.sessionDate));

    final isAboveThreshold =
        percentage != null && percentage >= subject.thresholdPct;
    final attendanceColor = percentage == null
        ? AppColors.textTertiary
        : isAboveThreshold
            ? AppColors.success
            : (percentage >= subject.thresholdPct - 10
                ? AppColors.warning
                : AppColors.error);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Back button row
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => context.go('/attendance'),
                    ),
                    const Spacer(),
                    PopupMenuButton(
                      icon: const Icon(Icons.more_vert_rounded),
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded,
                                  color: AppColors.error, size: 20),
                              SizedBox(width: 8),
                              Text('DELETE SUBJECT',
                                  style: TextStyle(color: AppColors.error)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'delete') _confirmDeleteSubject();
                      },
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subject code
                    if (subject.code != null)
                      Text(
                        subject.code!.toUpperCase(),
                        style: GoogleFonts.dmMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.2,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                        ),
                      ),
                    // Subject name
                    Text(
                      subject.name,
                      style: GoogleFonts.bigShoulders(
                        fontSize: 46,
                        fontWeight: FontWeight.w900,
                        height: 0.88,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Big attendance card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: attendanceColor,
                        border: Border.all(
                            color: borderColor, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: shadowColor,
                            offset: const Offset(7, 7),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ATTENDANCE',
                                      style: GoogleFonts.dmMono(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 1.0,
                                        color: Colors.black,
                                      ),
                                    ),
                                    Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(
                                            text: percentage != null
                                                ? '${percentage.round()}'
                                                : '--',
                                            style: GoogleFonts.bigShoulders(
                                              fontSize: 76,
                                              fontWeight: FontWeight.w900,
                                              height: 0.85,
                                              color: Colors.black,
                                            ),
                                          ),
                                          TextSpan(
                                            text: '%',
                                            style: GoogleFonts.bigShoulders(
                                              fontSize: 30,
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
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '$attended / $total',
                                    style: GoogleFonts.dmMono(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    'REQ ${subject.thresholdPct}%',
                                    style: GoogleFonts.dmMono(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          // Session strip
                          if (sessions.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 26,
                              child: Row(
                                children: sessions
                                    .take(12)
                                    .toList()
                                    .reversed
                                    .map((s) => Expanded(
                                          child: Container(
                                            margin:
                                                const EdgeInsets.only(right: 3),
                                            decoration: BoxDecoration(
                                              color: s.isPresent
                                                  ? Colors.black
                                                  : (isDark
                                                      ? AppColors.backgroundDark
                                                      : Colors.white),
                                              border: Border.all(
                                                  color: Colors.black,
                                                  width: 2),
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Safe to skip / warning banner
                    if (percentage != null) _buildWarningBanner(
                      isDark: isDark,
                      borderColor: borderColor,
                      shadowColor: shadowColor,
                      safeToSkip: safeToSkip,
                      classesNeeded: classesNeeded,
                      isAboveThreshold: isAboveThreshold,
                      thresholdPct: subject.thresholdPct,
                    ),

                    // PRESENT / ABSENT buttons
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              ref
                                  .read(
                                      attendanceViewModelProvider.notifier)
                                  .logAttendance(
                                    subjectId: widget.subjectId,
                                    date: DateTime.now(),
                                    status: AttendanceStatus.present,
                                  );
                            },
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 15),
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                border:
                                    Border.all(color: borderColor, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: shadowColor,
                                    offset:
                                        const Offset(5, 5),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  'PRESENT',
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
                        const SizedBox(width: 9),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              ref
                                  .read(
                                      attendanceViewModelProvider.notifier)
                                  .logAttendance(
                                    subjectId: widget.subjectId,
                                    date: DateTime.now(),
                                    status: AttendanceStatus.absent,
                                  );
                            },
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 15),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                border:
                                    Border.all(color: borderColor, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: shadowColor,
                                    offset:
                                        const Offset(5, 5),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  'ABSENT',
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
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Recent sessions header
                    Text(
                      'RECENT SESSIONS',
                      style: GoogleFonts.dmMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.0,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // Session list
            if (sessions.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration:
                        NeoBrutalism.flatCardDecoration(isDark: isDark),
                    child: Center(
                      child: Text(
                        'NO SESSIONS LOGGED YET',
                        style: GoogleFonts.dmMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                sliver: SliverList.separated(
                  itemCount: sessions.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 7),
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceDark
                            : AppColors.surface,
                        border: Border.all(color: borderColor, width: 3),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              DateFormat('EEE d MMM')
                                  .format(session.sessionDate),
                              style: GoogleFonts.archivo(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 4),
                            decoration: BoxDecoration(
                              color: session.isPresent
                                  ? AppColors.success
                                  : AppColors.error,
                              border:
                                  Border.all(color: borderColor, width: 2),
                            ),
                            child: Text(
                              session.isPresent ? 'PRESENT' : 'ABSENT',
                              style: GoogleFonts.dmMono(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningBanner({
    required bool isDark,
    required Color borderColor,
    required Color shadowColor,
    required int safeToSkip,
    required int classesNeeded,
    required bool isAboveThreshold,
    required int thresholdPct,
  }) {
    final String title;
    final String subtitle;

    if (isAboveThreshold && safeToSkip > 0) {
      title = 'SAFE TO SKIP: $safeToSkip';
      subtitle =
          'Miss ${safeToSkip == 1 ? "another" : "more than $safeToSkip"} and you drop under $thresholdPct%.';
    } else if (isAboveThreshold && safeToSkip == 0) {
      title = 'AT THRESHOLD';
      subtitle = 'You\'re right at $thresholdPct%. Don\'t skip any classes!';
    } else if (!isAboveThreshold && classesNeeded > 0) {
      title = 'NEED $classesNeeded MORE';
      subtitle =
          'Attend the next $classesNeeded class${classesNeeded == 1 ? '' : 'es'} to reach $thresholdPct%.';
    } else {
      return const SizedBox(height: 14);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.warning,
          border: Border.all(color: borderColor, width: 3),
          boxShadow: [
            BoxShadow(color: shadowColor, offset: const Offset(5, 5)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.bigShoulders(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                height: 1.0,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
                style: GoogleFonts.archivo(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                  color: Colors.black,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
