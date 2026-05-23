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

  factory FriendshipDto.fromJson(Map<String, dynamic> json) => FriendshipDto(
        id: json['id'],
        requesterId: json['requester_id'],
        receiverId: json['receiver_id'],
        status: json['status'] ?? 'pending',
        requesterName: json['requester_name'],
        receiverName: json['receiver_name'],
        requesterPhotoUrl: json['requester_photo_url'],
        receiverPhotoUrl: json['receiver_photo_url'],
        createdAt: json['created_at'],
        updatedAt: json['updated_at'],
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
