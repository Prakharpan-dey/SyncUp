import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/current_user.dart';
import '../../domain/entities/friendship.dart';
import '../../domain/entities/group.dart';
import '../../domain/entities/group_invite.dart';
import '../../domain/entities/group_join_request.dart';
import '../../domain/entities/group_member.dart';
import '../../domain/entities/user_summary.dart';
import '../../di/social_providers.dart';

class SocialState {
  final List<UserSummary> searchResults;
  final List<UserSummary> friends;
  final List<Friendship> pendingRequests;
  final List<Group> groups;
  final Group? selectedGroup;
  final List<GroupMember> groupMembers;

  /// Waiting to join [selectedGroup]. Only ever filled for its owner or admins.
  final List<GroupJoinRequest> joinRequests;

  /// Invites [selectedGroup] has sent that are still unanswered — admins only.
  final List<SentGroupInvite> sentInvites;

  /// Invites waiting on the current user, from any group.
  final List<GroupInvite> myInvites;
  final bool isLoading;
  final String? error;

  const SocialState({
    this.searchResults = const [],
    this.friends = const [],
    this.pendingRequests = const [],
    this.groups = const [],
    this.selectedGroup,
    this.groupMembers = const [],
    this.joinRequests = const [],
    this.sentInvites = const [],
    this.myInvites = const [],
    this.isLoading = false,
    this.error,
  });

  SocialState copyWith({
    List<UserSummary>? searchResults,
    List<UserSummary>? friends,
    List<Friendship>? pendingRequests,
    List<Group>? groups,
    Group? selectedGroup,
    List<GroupMember>? groupMembers,
    List<GroupJoinRequest>? joinRequests,
    List<SentGroupInvite>? sentInvites,
    List<GroupInvite>? myInvites,
    bool? isLoading,
    String? error,
  }) =>
      SocialState(
        searchResults: searchResults ?? this.searchResults,
        friends: friends ?? this.friends,
        pendingRequests: pendingRequests ?? this.pendingRequests,
        groups: groups ?? this.groups,
        selectedGroup: selectedGroup ?? this.selectedGroup,
        groupMembers: groupMembers ?? this.groupMembers,
        joinRequests: joinRequests ?? this.joinRequests,
        sentInvites: sentInvites ?? this.sentInvites,
        myInvites: myInvites ?? this.myInvites,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class SocialViewModel extends Notifier<SocialState> {
  @override
  SocialState build() => const SocialState();

  // Search

  Future<void> searchUsers(String query) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await ref.read(searchUsersUseCaseProvider)(query);
    result.fold(
      (f) => state = state.copyWith(isLoading: false, error: f.message),
      (users) =>
          state = state.copyWith(isLoading: false, searchResults: users),
    );
  }

  void clearSearch() {
    state = state.copyWith(searchResults: []);
  }

  // Friends

  Future<void> loadFriends(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    final result =
        await ref.read(socialRepositoryProvider).getFriends(userId);
    result.fold(
      (f) => state = state.copyWith(isLoading: false, error: f.message),
      (friends) =>
          state = state.copyWith(isLoading: false, friends: friends),
    );
  }

  Future<void> loadPendingRequests(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    final result =
        await ref.read(socialRepositoryProvider).getPendingRequests(userId);
    result.fold(
      (f) => state = state.copyWith(isLoading: false, error: f.message),
      (requests) => state =
          state.copyWith(isLoading: false, pendingRequests: requests),
    );
  }

  /// Whether the request was sent.
  Future<bool> sendFriendRequest({
    required String requesterId,
    required String receiverId,
  }) async {
    state = state.copyWith(error: null);
    final result = await ref.read(sendFriendRequestUseCaseProvider)(
      requesterId: requesterId,
      receiverId: receiverId,
    );
    return result.fold(
      (f) {
        state = state.copyWith(error: f.message);
        return false;
      },
      (_) {
        // Dropped from the results — the screen says the request went out.
        state = state.copyWith(
          searchResults:
              state.searchResults.where((u) => u.id != receiverId).toList(),
        );
        return true;
      },
    );
  }

  Future<void> respondToRequest({
    required String requestId,
    required FriendshipStatus response,
  }) async {
    state = state.copyWith(error: null);
    final result = await ref.read(manageFriendRequestUseCaseProvider)(
      requestId: requestId,
      response: response,
    );
    final ok = result.fold(
      (f) {
        state = state.copyWith(error: f.message);
        return false;
      },
      (_) {
        state = state.copyWith(
          pendingRequests:
              state.pendingRequests.where((r) => r.id != requestId).toList(),
        );
        return true;
      },
    );

    // Accepting creates a friendship, which the Friends tab reads from a
    // separate list. Without this refresh it keeps reporting the old count
    // until the screen is rebuilt from scratch.
    if (ok && response == FriendshipStatus.accepted) {
      await loadFriends(ref.read(currentUserIdProvider));
    }
  }

  Future<void> removeFriend(String friendshipId, String friendUserId) async {
    state = state.copyWith(error: null);
    final result =
        await ref.read(socialRepositoryProvider).removeFriend(friendshipId);
    result.fold(
      (f) => state = state.copyWith(error: f.message),
      (_) {
        state = state.copyWith(
          friends:
              state.friends.where((f) => f.id != friendUserId).toList(),
        );
      },
    );
  }

  // Groups

  Future<void> loadGroups(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    final result =
        await ref.read(socialRepositoryProvider).getGroups(userId);
    result.fold(
      (f) => state = state.copyWith(isLoading: false, error: f.message),
      (groups) =>
          state = state.copyWith(isLoading: false, groups: groups),
    );
  }

  Future<void> createGroup({
    required String name,
    required String createdBy,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await ref.read(createGroupUseCaseProvider)(
      name: name,
      createdBy: createdBy,
    );
    result.fold(
      (f) => state = state.copyWith(isLoading: false, error: f.message),
      (group) => state = state.copyWith(
        isLoading: false,
        groups: [...state.groups, group],
      ),
    );
  }

  Future<void> loadGroupDetail(String groupId) async {
    // Cleared first so one group's waiting list never shows under another.
    state = state.copyWith(
        isLoading: true,
        error: null,
        joinRequests: const [],
        sentInvites: const []);
    final detailResult =
        await ref.read(socialRepositoryProvider).getGroupDetail(groupId);
    final membersResult =
        await ref.read(socialRepositoryProvider).getGroupMembers(groupId);

    detailResult.fold(
      (f) => state = state.copyWith(isLoading: false, error: f.message),
      (group) {
        membersResult.fold(
          (f) => state = state.copyWith(
              isLoading: false, selectedGroup: group, error: f.message),
          (members) => state = state.copyWith(
              isLoading: false, selectedGroup: group, groupMembers: members),
        );
      },
    );

    // Only the owner and admins may see who is waiting — the server 403s
    // anyone else — so the list is fetched for them alone.
    final me = ref.read(currentUserIdProvider);
    final group = state.selectedGroup;
    final canManage = group != null &&
        group.id == groupId &&
        (group.createdBy == me ||
            state.groupMembers.any((m) => m.userId == me && m.isAdmin));
    if (canManage) {
      await loadJoinRequests(groupId);
      await loadSentInvites(groupId);
    }
  }

  Future<void> loadSentInvites(String groupId) async {
    final result =
        await ref.read(socialRepositoryProvider).getGroupInvites(groupId);
    result.fold(
      (f) => state = state.copyWith(error: f.message),
      (invites) => state = state.copyWith(sentInvites: invites),
    );
  }

  /// Invites someone by exactly one of [username], [email] or [userId].
  ///
  /// Returns what to tell the admin rather than setting [SocialState.error]:
  /// "No SyncUp account with that email" is an answer to show in the sheet,
  /// not a banner over the whole screen.
  Future<({bool ok, String message})> inviteToGroup({
    required String groupId,
    String? username,
    String? email,
    String? userId,
  }) async {
    final result = await ref.read(socialRepositoryProvider).inviteToGroup(
          groupId: groupId,
          username: username,
          email: email,
          userId: userId,
        );
    final failure = result.getLeft().toNullable();
    if (failure != null) return (ok: false, message: failure.message);

    final joined = result.getOrElse((_) => 'invited') == 'member';
    // Either the member list or the invited list changed.
    await loadGroupDetail(groupId);
    return (
      ok: true,
      message: joined
          ? 'They had already asked to join, so they are in now'
          : 'Invite sent',
    );
  }

  Future<void> cancelInvite(String groupId, String inviteId) async {
    state = state.copyWith(error: null);
    final result = await ref
        .read(socialRepositoryProvider)
        .cancelInvite(groupId: groupId, inviteId: inviteId);
    result.fold(
      (f) => state = state.copyWith(error: f.message),
      (_) => state = state.copyWith(
        sentInvites: state.sentInvites.where((i) => i.id != inviteId).toList(),
      ),
    );
  }

  Future<void> loadMyInvites() async {
    final result = await ref.read(socialRepositoryProvider).getMyInvites();
    result.fold(
      (f) => state = state.copyWith(error: f.message),
      (invites) => state = state.copyWith(myInvites: invites),
    );
  }

  /// Joins the group. Reloads the group list, where it now appears.
  Future<bool> acceptInvite(String inviteId) async {
    state = state.copyWith(error: null);
    final result =
        await ref.read(socialRepositoryProvider).acceptInvite(inviteId);
    final failure = result.getLeft().toNullable();
    if (failure != null) {
      state = state.copyWith(error: failure.message);
      return false;
    }
    state = state.copyWith(
      myInvites: state.myInvites.where((i) => i.id != inviteId).toList(),
    );
    await loadGroups(ref.read(currentUserIdProvider));
    return true;
  }

  Future<void> declineInvite(String inviteId) async {
    state = state.copyWith(error: null);
    final result =
        await ref.read(socialRepositoryProvider).declineInvite(inviteId);
    result.fold(
      (f) => state = state.copyWith(error: f.message),
      (_) => state = state.copyWith(
        myInvites: state.myInvites.where((i) => i.id != inviteId).toList(),
      ),
    );
  }

  Future<void> loadJoinRequests(String groupId) async {
    final result =
        await ref.read(socialRepositoryProvider).getJoinRequests(groupId);
    result.fold(
      (f) => state = state.copyWith(error: f.message),
      (requests) => state = state.copyWith(joinRequests: requests),
    );
  }

  /// Lets a waiting user in. Reloads the group so the new member and the
  /// header count both reflect what the server now holds.
  Future<void> approveJoinRequest(String groupId, String requestId) async {
    state = state.copyWith(error: null);
    final result = await ref
        .read(socialRepositoryProvider)
        .approveJoinRequest(groupId: groupId, requestId: requestId);
    await result.fold(
      (f) async => state = state.copyWith(error: f.message),
      (_) async => loadGroupDetail(groupId),
    );
  }

  Future<void> rejectJoinRequest(String groupId, String requestId) async {
    state = state.copyWith(error: null);
    final result = await ref
        .read(socialRepositoryProvider)
        .rejectJoinRequest(groupId: groupId, requestId: requestId);
    result.fold(
      (f) => state = state.copyWith(error: f.message),
      (_) => state = state.copyWith(
        joinRequests:
            state.joinRequests.where((r) => r.id != requestId).toList(),
      ),
    );
  }

  /// Removes another member. Owner-only; the server enforces that.
  Future<void> removeMember(String groupId, String userId) async {
    state = state.copyWith(error: null);
    final result = await ref
        .read(socialRepositoryProvider)
        .removeMember(groupId: groupId, userId: userId);
    result.fold(
      (f) => state = state.copyWith(error: f.message),
      (_) {
        // Dropped locally rather than refetching: the list is already loaded
        // and the removal is the only change the server made. The header count
        // comes from a separate field, so it has to move too or the card reads
        // "3 members" above a list of two.
        final remaining =
            state.groupMembers.where((m) => m.userId != userId).toList();
        state = state.copyWith(
          groupMembers: remaining,
          selectedGroup: state.selectedGroup
              ?.copyWith(memberCount: remaining.length),
        );
      },
    );
  }

  Future<void> leaveGroup(String groupId, String userId) async {
    state = state.copyWith(error: null);
    final result =
        await ref.read(socialRepositoryProvider).leaveGroup(groupId, userId);
    result.fold(
      (f) => state = state.copyWith(error: f.message),
      (_) {
        state = state.copyWith(
          groups: state.groups.where((g) => g.id != groupId).toList(),
        );
      },
    );
  }
}

final socialViewModelProvider =
    NotifierProvider<SocialViewModel, SocialState>(SocialViewModel.new);
