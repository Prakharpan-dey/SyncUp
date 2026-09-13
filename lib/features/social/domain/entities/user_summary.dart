import 'package:equatable/equatable.dart';

/// Lightweight user info for search results and friend/member lists
class UserSummary extends Equatable {
  final String id;
  final String username;
  final String displayName;
  final String? photoUrl;

  /// Where you stand with them, on a search result: 'friends', 'requested'
  /// (you asked), 'incoming' (they asked) or 'none'. Null elsewhere.
  final String? friendshipStatus;

  const UserSummary({
    required this.id,
    required this.username,
    required this.displayName,
    this.photoUrl,
    this.friendshipStatus,
  });

  @override
  List<Object?> get props => [id];
}
