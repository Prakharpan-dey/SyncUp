import 'package:equatable/equatable.dart';

enum GroupRole { admin, member }

// A per-group SharingOverride was modelled here, parsed from a `sharing_override`
// field the server has never sent, and read by nothing. It described a control
// that does not exist: group membership currently means every shared completion
// reaches every group, with no opt-out. Removed rather than left in place, so
// the model stops implying a setting the app cannot honour. Per-task privacy is
// the control that does work — see Task.sharingOverride.

class GroupMember extends Equatable {
  final String groupId;
  final String userId;
  final String displayName;
  final String? photoUrl;
  final GroupRole role;

  const GroupMember({
    required this.groupId,
    required this.userId,
    required this.displayName,
    this.photoUrl,
    this.role = GroupRole.member,
  });

  bool get isAdmin => role == GroupRole.admin;

  @override
  List<Object?> get props => [groupId, userId];
}
