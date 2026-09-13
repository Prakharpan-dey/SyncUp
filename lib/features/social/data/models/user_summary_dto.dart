import '../../domain/entities/user_summary.dart';

class UserSummaryDto {
  final String id, username, displayName;
  final String? photoUrl, friendshipStatus;

  const UserSummaryDto({
    required this.id,
    required this.username,
    required this.displayName,
    this.photoUrl,
    this.friendshipStatus,
  });

  factory UserSummaryDto.fromJson(Map<String, dynamic> json) => UserSummaryDto(
        id: json['id'],
        username: json['username'],
        displayName: json['display_name'],
        photoUrl: json['photo_url'],
        friendshipStatus: json['friendship_status'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'display_name': displayName,
        'photo_url': photoUrl,
      };

  UserSummary toDomain() => UserSummary(
        id: id,
        username: username,
        displayName: displayName,
        photoUrl: photoUrl,
        friendshipStatus: friendshipStatus,
      );
}
