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

  /// [groupId] is supplied by the caller because `GET /groups/:id/members`
  /// does not repeat it in each row — reading `group_id` off the payload gave
  /// null for a non-nullable field and threw.
  factory GroupMemberDto.fromJson(
    Map<String, dynamic> json, {
    required String groupId,
  }) =>
      GroupMemberDto(
        groupId: groupId,
        userId: json['user_id'] as String,
        displayName: json['display_name'] as String? ?? '',
        role: json['role'] as String? ?? 'member',
        photoUrl: json['photo_url'] as String?,
        sharingOverride: json['sharing_override'] as String? ?? 'inherit',
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
        role: _role(role),
        sharingOverride: _sharing(sharingOverride),
      );

  /// The server's roles are `owner` and `member`; the app models an owner as an
  /// admin. `byName` threw on `owner`, which took out the whole member list.
  static GroupRole _role(String value) => switch (value) {
        'owner' || 'admin' => GroupRole.admin,
        _ => GroupRole.member,
      };

  static SharingOverride _sharing(String value) =>
      SharingOverride.values.asNameMap()[value] ?? SharingOverride.inherit;
}
