import 'package:equatable/equatable.dart';

enum FriendshipStatus { pending, accepted, rejected, blocked }

class Friendship extends Equatable {
  final String id;
  final String requesterId;
  final String receiverId;
  final FriendshipStatus status;
  final String? requesterName;
  final String? receiverName;
  final String? requesterPhotoUrl;
  final String? receiverPhotoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Friendship({
    required this.id,
    required this.requesterId,
    required this.receiverId,
    required this.status,
    this.requesterName,
    this.receiverName,
    this.requesterPhotoUrl,
    this.receiverPhotoUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  Friendship copyWith({FriendshipStatus? status, DateTime? updatedAt}) =>
      Friendship(
        id: id,
        requesterId: requesterId,
        receiverId: receiverId,
        status: status ?? this.status,
        requesterName: requesterName,
        receiverName: receiverName,
        requesterPhotoUrl: requesterPhotoUrl,
        receiverPhotoUrl: receiverPhotoUrl,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );

  @override
  List<Object?> get props => [id];
}
