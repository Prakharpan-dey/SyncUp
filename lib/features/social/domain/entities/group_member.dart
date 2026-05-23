import 'package:equatable/equatable.dart';

enum GroupRole { admin, member }

enum SharingOverride { inherit, none, summary, selected, all }

class GroupMember extends Equatable {
  final String groupId;
  final String userId;
  final String displayName;
  final String? photoUrl;
  final GroupRole role;
  final SharingOverride sharingOverride;

  const GroupMember({
    required this.groupId,
    required this.userId,
    required this.displayName,
    this.photoUrl,
    this.role = GroupRole.member,
    this.sharingOverride = SharingOverride.inherit,
  });

  bool get isAdmin => role == GroupRole.admin;

  @override
  List<Object?> get props => [groupId, userId];
}
