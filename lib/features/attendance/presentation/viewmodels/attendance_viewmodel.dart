import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/subject.dart';
import '../../domain/entities/attendance_session.dart';
import '../../di/attendance_providers.dart';

class AttendanceState {
  final List<Subject> subjects;
  final List<AttendanceSession> sessions;
  final String? selectedSubjectId;
  final bool isLoading;
  final String? error;

  const AttendanceState({
    this.subjects = const [],
    this.sessions = const [],
    this.selectedSubjectId,
    this.isLoading = false,
    this.error,
  });

  AttendanceState copyWith({
    List<Subject>? subjects,
    List<AttendanceSession>? sessions,
    String? selectedSubjectId,
    bool? isLoading,
    String? error,
  }) =>
      AttendanceState(
        subjects: subjects ?? this.subjects,
        sessions: sessions ?? this.sessions,
        selectedSubjectId: selectedSubjectId ?? this.selectedSubjectId,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );

  /// Get the currently selected subject.
  Subject? get selectedSubject {
    if (selectedSubjectId == null) return null;
    try {
      return subjects.firstWhere((s) => s.id == selectedSubjectId);
    } catch (_) {
      return null;
    }
  }

  /// Count sessions for a given subject.
  int totalClasses(String subjectId) =>
      sessions.where((s) => s.subjectId == subjectId).length;

  int attendedClasses(String subjectId) => sessions
      .where(
          (s) => s.subjectId == subjectId && s.status == AttendanceStatus.present)
      .length;

  /// Attendance percentage for a subject. Returns null if no classes logged.
  double? attendancePercentage(String subjectId) {
    final total = totalClasses(subjectId);
    if (total == 0) return null;
    return (attendedClasses(subjectId) / total) * 100;
  }
}

class AttendanceViewModel extends Notifier<AttendanceState> {
  @override
  AttendanceState build() => const AttendanceState(isLoading: true);

  Future<void> loadSubjects(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    final result =
        await ref.read(attendanceRepositoryProvider).getSubjects(userId);
    result.fold(
      (f) => state = state.copyWith(isLoading: false, error: f.message),
      (subjects) async {
        // Also load all sessions for every subject so list screen shows
        // correct percentages and class counts immediately.
        final allSessions = <AttendanceSession>[];
        for (final subject in subjects) {
          final sessionsResult = await ref
              .read(attendanceRepositoryProvider)
              .getSessionsForSubject(subject.id);
          sessionsResult.fold(
            (_) {},
            (sessions) => allSessions.addAll(sessions),
          );
        }
        allSessions.sort((a, b) => b.sessionDate.compareTo(a.sessionDate));
        state = state.copyWith(
            isLoading: false, subjects: subjects, sessions: allSessions);
      },
    );
  }

  Future<void> addSubject({
    required String userId,
    required String name,
    String? code,
    int thresholdPct = 75,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await ref.read(createSubjectUseCaseProvider)(
      userId: userId,
      name: name,
      code: code,
      thresholdPct: thresholdPct,
    );
    result.fold(
      (f) => state = state.copyWith(isLoading: false, error: f.message),
      (subject) => state = state.copyWith(
        isLoading: false,
        subjects: [...state.subjects, subject],
      ),
    );
  }

  Future<void> deleteSubject(String subjectId) async {
    final result =
        await ref.read(attendanceRepositoryProvider).deleteSubject(subjectId);
    result.fold(
      (f) => state = state.copyWith(error: f.message),
      (_) {
        state = state.copyWith(
          subjects: state.subjects.where((s) => s.id != subjectId).toList(),
          sessions:
              state.sessions.where((s) => s.subjectId != subjectId).toList(),
        );
      },
    );
  }

  Future<void> loadSessions(String subjectId) async {
    state = state.copyWith(
        isLoading: true, error: null, selectedSubjectId: subjectId);
    final result = await ref
        .read(attendanceRepositoryProvider)
        .getSessionsForSubject(subjectId);
    result.fold(
      (f) => state = state.copyWith(isLoading: false, error: f.message),
      (sessions) => state = state.copyWith(isLoading: false, sessions: sessions),
    );
  }

  Future<void> logAttendance({
    required String subjectId,
    required DateTime date,
    required AttendanceStatus status,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await ref.read(logAttendanceUseCaseProvider)(
      subjectId: subjectId,
      date: date,
      status: status,
    );
    result.fold(
      (f) => state = state.copyWith(isLoading: false, error: f.message),
      (session) {
        final updated = [session, ...state.sessions]
          ..sort((a, b) => b.sessionDate.compareTo(a.sessionDate));
        state = state.copyWith(isLoading: false, sessions: updated);
      },
    );
  }

  Future<void> deleteSession(String sessionId) async {
    final result =
        await ref.read(attendanceRepositoryProvider).deleteSession(sessionId);
    result.fold(
      (f) => state = state.copyWith(error: f.message),
      (_) {
        state = state.copyWith(
          sessions: state.sessions.where((s) => s.id != sessionId).toList(),
        );
      },
    );
  }

  /// Calculate classes needed to reach threshold for a subject.
  int classesNeeded(String subjectId) {
    final subject = state.subjects.where((s) => s.id == subjectId).firstOrNull;
    if (subject == null) return 0;
    return ref.read(calculateClassesNeededProvider)(
      attended: state.attendedClasses(subjectId),
      total: state.totalClasses(subjectId),
      threshold: subject.thresholdFraction,
    );
  }

  /// Calculate safe classes to skip for a subject.
  int safeToSkip(String subjectId) {
    final subject = state.subjects.where((s) => s.id == subjectId).firstOrNull;
    if (subject == null) return 0;
    return ref.read(calculateSafeToSkipProvider)(
      attended: state.attendedClasses(subjectId),
      total: state.totalClasses(subjectId),
      threshold: subject.thresholdFraction,
    );
  }
}

final attendanceViewModelProvider =
    NotifierProvider<AttendanceViewModel, AttendanceState>(
        AttendanceViewModel.new);
