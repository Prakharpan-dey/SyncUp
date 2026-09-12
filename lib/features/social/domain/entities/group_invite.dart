import 'package:equatable/equatable.dart';

import 'user_summary.dart';

/// An invite waiting on the current user: someone asked them into a group.
///
/// The group itself stays out of their list until they accept — an invite is
/// the only thing they can see of it.
class GroupInvite extends Equatable {
  final String id;
  final String groupId;
  final String groupName;
  final String? invitedByName;
  final DateTime createdAt;

  const GroupInvite({
    required this.id,
    required this.groupId,
    required this.groupName,
    this.invitedByName,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id];
}

/// An invite a group's owner or admin sent that nobody has answered yet.
class SentGroupInvite extends Equatable {
  final String id;
  final UserSummary user;
  final DateTime createdAt;

  const SentGroupInvite({
    required this.id,
    required this.user,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id];
}
