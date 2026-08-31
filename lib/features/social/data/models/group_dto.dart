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

  /// The API calls the owner `owner_id`; reading `created_by` yielded null for
  /// a non-nullable field and threw, so creating a group and listing groups
  /// both failed even though the server had done the work.
  ///
  /// `member_count` is not returned by any group endpoint, so it stays 0.
  factory GroupDto.fromJson(Map<String, dynamic> json) => GroupDto(
        id: json['id'] as String,
        name: json['name'] as String,
        createdBy:
            json['owner_id'] as String? ?? json['created_by'] as String? ?? '',
        inviteToken: json['invite_token'] as String?,
        memberCount: json['member_count'] as int? ?? 0,
        createdAt: json['created_at'] as String?,
        updatedAt: json['updated_at'] as String?,
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
