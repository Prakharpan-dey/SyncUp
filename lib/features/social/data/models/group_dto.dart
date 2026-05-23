import '../../domain/entities/group.dart';

class GroupDto {
  final String id, name, createdBy;
  final String? inviteToken;
  final int memberCount;
  final String? createdAt, updatedAt;

  const GroupDto({
    required this.id,
    required this.name,
    required this.createdBy,
    this.inviteToken,
    this.memberCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory GroupDto.fromJson(Map<String, dynamic> json) => GroupDto(
        id: json['id'],
        name: json['name'],
        createdBy: json['created_by'],
        inviteToken: json['invite_token'],
        memberCount: json['member_count'] ?? 0,
        createdAt: json['created_at'],
        updatedAt: json['updated_at'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'created_by': createdBy,
        'invite_token': inviteToken,
      };

  Group toDomain() => Group(
        id: id,
        name: name,
        createdBy: createdBy,
        inviteToken: inviteToken,
        memberCount: memberCount,
        createdAt:
            createdAt != null ? DateTime.parse(createdAt!) : DateTime.now(),
        updatedAt:
            updatedAt != null ? DateTime.parse(updatedAt!) : DateTime.now(),
      );
}
