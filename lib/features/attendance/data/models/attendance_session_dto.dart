import '../../../../core/utils/date_helpers.dart';
import '../../domain/entities/attendance_session.dart';

class AttendanceSessionDto {
  final String id, subjectId, status;
  final String sessionDate;
  final String? createdAt, updatedAt;

  const AttendanceSessionDto({
    required this.id,
    required this.subjectId,
    required this.sessionDate,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory AttendanceSessionDto.fromJson(Map<String, dynamic> json) =>
      AttendanceSessionDto(
        id: json['id'],
        subjectId: json['subject_id'],
        sessionDate: json['session_date'],
        status: json['status'] ?? 'present',
        createdAt: json['created_at'],
        updatedAt: json['updated_at'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'subject_id': subjectId,
        'session_date': sessionDate,
        'status': status,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  AttendanceSession toDomain() => AttendanceSession(
        id: id,
        subjectId: subjectId,
        sessionDate: DateTime.parse(sessionDate),
        status: AttendanceStatus.values.byName(status),
        createdAt:
            createdAt != null ? DateTime.parse(createdAt!) : DateTime.now(),
        updatedAt:
            updatedAt != null ? DateTime.parse(updatedAt!) : DateTime.now(),
      );

  factory AttendanceSessionDto.fromDomain(AttendanceSession s) =>
      AttendanceSessionDto(
        id: s.id,
        subjectId: s.subjectId,
        // Date-only: the API validates session_date as YYYY-MM-DD, and the
        // (subject_id, session_date) uniqueness constraint depends on it.
        sessionDate: DateHelpers.formatApiDate(s.sessionDate),
        status: s.status.name,
        createdAt: s.createdAt.toIso8601String(),
        updatedAt: s.updatedAt.toIso8601String(),
      );
}
