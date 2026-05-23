import 'package:equatable/equatable.dart';

/// Lightweight user info for search results and friend/member lists
class UserSummary extends Equatable {
  final String id;
  final String username;
  final String displayName;
  final String? photoUrl;

  const UserSummary({
    required this.id,
    required this.username,
    required this.displayName,
    this.photoUrl,
  });

  @override
  List<Object?> get props => [id];
}
