import '../../domain/entities/friendship.dart';

class FriendshipDto {
  final String id, requesterId, receiverId, status;
  final String? requesterName, receiverName, requesterPhotoUrl, receiverPhotoUrl;
  final String? createdAt, updatedAt;

  const FriendshipDto({
    required this.id,
    required this.requesterId,
    required this.receiverId,
    required this.status,
    this.requesterName,
    this.receiverName,
    this.requesterPhotoUrl,
    this.receiverPhotoUrl,
    this.createdAt,
    this.updatedAt,
  });

  /// Builds from either shape the API returns.
  ///
  /// `GET /friends/requests` inlines the requester as `username` /
  /// `display_name` / `photo_url` and names no addressee at all, while
  /// `POST /friends/request` and `PATCH /friends/request/:id` return only `id`
  /// and `status`. Neither sends `receiver_id`, `requester_name` or
  /// `requester_photo_url`, so reading those directly into non-nullable fields
  /// threw and took out the whole friends screen.
  factory FriendshipDto.fromJson(Map<String, dynamic> json) => FriendshipDto(
        id: json['id'] as String,
        requesterId: json['requester_id'] as String? ?? '',
        receiverId: json['receiver_id'] as String? ?? '',
        status: json['status'] as String? ?? 'pending',
        requesterName:
            json['display_name'] as String? ?? json['requester_name'] as String?,
        receiverName: json['receiver_name'] as String?,
        requesterPhotoUrl:
            json['photo_url'] as String? ?? json['requester_photo_url'] as String?,
        receiverPhotoUrl: json['receiver_photo_url'] as String?,
        createdAt: json['created_at'] as String?,
        updatedAt: json['updated_at'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'requester_id': requesterId,
        'receiver_id': receiverId,
        'status': status,
      };

  Friendship toDomain() => Friendship(
        id: id,
        requesterId: requesterId,
        receiverId: receiverId,
        status: FriendshipStatus.values.byName(status),
        requesterName: requesterName,
        receiverName: receiverName,
        requesterPhotoUrl: requesterPhotoUrl,
        receiverPhotoUrl: receiverPhotoUrl,
        createdAt:
            createdAt != null ? DateTime.parse(createdAt!) : DateTime.now(),
        updatedAt:
            updatedAt != null ? DateTime.parse(updatedAt!) : DateTime.now(),
      );
}
