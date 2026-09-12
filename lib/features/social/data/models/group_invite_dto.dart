import '../../domain/entities/group_invite.dart';
import '../../domain/entities/user_summary.dart';

DateTime _parseDate(Object? value) =>
    DateTime.tryParse(value as String? ?? '') ?? DateTime.now();

/// One row of `GET /groups/invites` — invites waiting on the current user.
class GroupInviteDto {
  final Map<String, dynamic> json;
  const GroupInviteDto(this.json);

  factory GroupInviteDto.fromJson(Map<String, dynamic> json) =>
      GroupInviteDto(json);

  GroupInvite toDomain() => GroupInvite(
        id: json['id'] as String,
        groupId: json['group_id'] as String,
        groupName: json['group_name'] as String? ?? '',
        invitedByName: json['invited_by_name'] as String?,
        createdAt: _parseDate(json['created_at']),
      );
}

/// One row of `GET /groups/:id/invites` — invites a group has sent.
class SentGroupInviteDto {
  final Map<String, dynamic> json;
  const SentGroupInviteDto(this.json);

  factory SentGroupInviteDto.fromJson(Map<String, dynamic> json) =>
      SentGroupInviteDto(json);

  SentGroupInvite toDomain() => SentGroupInvite(
        id: json['id'] as String,
        user: UserSummary(
          id: json['user_id'] as String,
          username: json['username'] as String? ?? '',
          displayName: json['display_name'] as String? ?? '',
          photoUrl: json['photo_url'] as String?,
        ),
        createdAt: _parseDate(json['created_at']),
      );
}
