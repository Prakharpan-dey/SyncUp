import '../../domain/entities/subject.dart';

class SubjectDto {
  final String id, userId, name;
  final String? code;
  final int thresholdPct;
  final String? createdAt, updatedAt;

  const SubjectDto({
    required this.id,
    required this.userId,
    required this.name,
    this.code,
    this.thresholdPct = 75,
    this.createdAt,
    this.updatedAt,
  });

  factory SubjectDto.fromJson(Map<String, dynamic> json) => SubjectDto(
        id: json['id'],
        userId: json['user_id'],
        name: json['name'],
        code: json['code'],
        thresholdPct: json['threshold_pct'] ?? 75,
        createdAt: json['created_at'],
        updatedAt: json['updated_at'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'code': code,
        'threshold_pct': thresholdPct,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  Subject toDomain() => Subject(
        id: id,
        userId: userId,
        name: name,
        code: code,
        thresholdPct: thresholdPct,
        createdAt:
            createdAt != null ? DateTime.parse(createdAt!) : DateTime.now(),
        updatedAt:
            updatedAt != null ? DateTime.parse(updatedAt!) : DateTime.now(),
      );

  factory SubjectDto.fromDomain(Subject s) => SubjectDto(
        id: s.id,
        userId: s.userId,
        name: s.name,
        code: s.code,
        thresholdPct: s.thresholdPct,
        createdAt: s.createdAt.toIso8601String(),
        updatedAt: s.updatedAt.toIso8601String(),
      );
}
