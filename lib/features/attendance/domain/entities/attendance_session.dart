import 'package:equatable/equatable.dart';

enum AttendanceStatus { present, absent }

class AttendanceSession extends Equatable {
  final String id, subjectId;
  final DateTime sessionDate;
  final AttendanceStatus status;
  final DateTime createdAt, updatedAt;

  const AttendanceSession({
    required this.id,
    required this.subjectId,
    required this.sessionDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPresent => status == AttendanceStatus.present;

  AttendanceSession copyWith({
    AttendanceStatus? status,
    DateTime? sessionDate,
    DateTime? updatedAt,
  }) =>
      AttendanceSession(
        id: id,
        subjectId: subjectId,
        sessionDate: sessionDate ?? this.sessionDate,
        status: status ?? this.status,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );

  @override
  List<Object?> get props => [id];
}
