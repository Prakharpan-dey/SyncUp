import '../../domain/entities/group_member.dart';

class GroupMemberDto {
  final String groupId, userId, displayName, role;
  final String? photoUrl;
  final String sharingOverride;

  const GroupMemberDto({
    required this.groupId,
    required this.userId,
    required this.displayName,
    required this.role,
    this.photoUrl,
    this.sharingOverride = 'inherit',
  });

  factory GroupMemberDto.fromJson(Map<String, dynamic> json) => GroupMemberDto(
        groupId: json['group_id'],
        userId: json['user_id'],
        displayName: json['display_name'],
        role: json['role'] ?? 'member',
        photoUrl: json['photo_url'],
        sharingOverride: json['sharing_override'] ?? 'inherit',
      );

  Map<String, dynamic> toJson() => {
        'group_id': groupId,
        'user_id': userId,
        'display_name': displayName,
        'role': role,
        'sharing_override': sharingOverride,
      };

  GroupMember toDomain() => GroupMember(
        groupId: groupId,
        userId: userId,
        displayName: displayName,
        photoUrl: photoUrl,
        role: GroupRole.values.byName(role),
        sharingOverride: SharingOverride.values.byName(sharingOverride),
      );
}
