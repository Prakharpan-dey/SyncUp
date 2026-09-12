import '../../domain/entities/group_join_request.dart';
import '../../domain/entities/user_summary.dart';

/// One row of `GET /groups/:id/requests`.
class GroupJoinRequestDto {
  final String id, userId, username, displayName;
  final String? photoUrl, createdAt;

  const GroupJoinRequestDto({
    required this.id,
    required this.userId,
    required this.username,
    required this.displayName,
    this.photoUrl,
    this.createdAt,
  });

  factory GroupJoinRequestDto.fromJson(Map<String, dynamic> json) =>
      GroupJoinRequestDto(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        username: json['username'] as String? ?? '',
        displayName: json['display_name'] as String? ?? '',
        photoUrl: json['photo_url'] as String?,
        createdAt: json['created_at'] as String?,
      );

  GroupJoinRequest toDomain() => GroupJoinRequest(
        id: id,
        user: UserSummary(
          id: userId,
          username: username,
          displayName: displayName,
          photoUrl: photoUrl,
        ),
        createdAt: DateTime.tryParse(createdAt ?? '') ?? DateTime.now(),
      );
}
