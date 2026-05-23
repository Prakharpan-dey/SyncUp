import 'package:equatable/equatable.dart';

class Group extends Equatable {
  final String id;
  final String name;
  final String createdBy;
  final String? inviteToken;
  final int memberCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Group({
    required this.id,
    required this.name,
    required this.createdBy,
    this.inviteToken,
    this.memberCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Group copyWith({
    String? name,
    String? inviteToken,
    int? memberCount,
    DateTime? updatedAt,
  }) =>
      Group(
        id: id,
        name: name ?? this.name,
        createdBy: createdBy,
        inviteToken: inviteToken ?? this.inviteToken,
        memberCount: memberCount ?? this.memberCount,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );

  @override
  List<Object?> get props => [id];
}
