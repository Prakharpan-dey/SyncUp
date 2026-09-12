import 'package:equatable/equatable.dart';

import 'user_summary.dart';

/// Someone who opened a group's invite link and is waiting for an owner or
/// admin to let them in.
class GroupJoinRequest extends Equatable {
  final String id;
  final UserSummary user;
  final DateTime createdAt;

  const GroupJoinRequest({
    required this.id,
    required this.user,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id];
}
