import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/friendship.dart';
import '../../domain/entities/group.dart';
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
  final bool isLoading;
  final String? error;

  const SocialState({
    this.searchResults = const [],
    this.friends = const [],
    this.pendingRequests = const [],
    this.groups = const [],
    this.selectedGroup,
    this.groupMembers = const [],
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

  Future<void> sendFriendRequest({
    required String requesterId,
    required String receiverId,
  }) async {
    state = state.copyWith(error: null);
    final result = await ref.read(sendFriendRequestUseCaseProvider)(
      requesterId: requesterId,
      receiverId: receiverId,
    );
    result.fold(
      (f) => state = state.copyWith(error: f.message),
      (_) {
        // Remove from search results to indicate request sent
        state = state.copyWith(
          searchResults:
              state.searchResults.where((u) => u.id != receiverId).toList(),
        );
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
    result.fold(
      (f) => state = state.copyWith(error: f.message),
      (friendship) {
        state = state.copyWith(
          pendingRequests:
              state.pendingRequests.where((r) => r.id != requestId).toList(),
        );
      },
    );
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
    state = state.copyWith(isLoading: true, error: null);
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
