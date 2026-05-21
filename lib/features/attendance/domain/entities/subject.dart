import 'package:equatable/equatable.dart';

class Subject extends Equatable {
  final String id, userId, name;
  final String? code;
  final int thresholdPct;
  final DateTime createdAt, updatedAt;

  const Subject({
    required this.id,
    required this.userId,
    required this.name,
    this.code,
    this.thresholdPct = 75,
    required this.createdAt,
    required this.updatedAt,
  });

  double get thresholdFraction => thresholdPct / 100.0;

  Subject copyWith({
    String? name,
    String? code,
    int? thresholdPct,
    DateTime? updatedAt,
  }) =>
      Subject(
        id: id,
        userId: userId,
        name: name ?? this.name,
        code: code ?? this.code,
        thresholdPct: thresholdPct ?? this.thresholdPct,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );

  @override
  List<Object?> get props => [id];
}
