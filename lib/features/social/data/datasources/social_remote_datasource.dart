import 'package:dio/dio.dart';

class SocialRemoteDataSource {
  final Dio _dio;
  SocialRemoteDataSource(this._dio);

  /// Reads a list response.
  ///
  /// Every list endpoint here returns a bare JSON array. These methods used to
  /// unwrap an envelope (`res.data['friends']`, `['requests']`, `['groups']`),
  /// which indexes a List with a String and throws — the repositories caught it
  /// and reported an empty list, so friends, pending requests, groups, members
  /// and user search all silently rendered as empty.
  static List<Map<String, dynamic>> _list(dynamic data) {
    if (data is! List) return const [];
    return data.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }

  // Users

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final res =
        await _dio.get('/users/search', queryParameters: {'q': query});
    return _list(res.data);
  }

  // Friends

  Future<List<Map<String, dynamic>>> getFriends(String userId) async {
    final res = await _dio.get('/friends');
    return _list(res.data);
  }

  Future<List<Map<String, dynamic>>> getPendingRequests(String userId) async {
    final res = await _dio.get('/friends/requests');
    return _list(res.data);
  }

  Future<Map<String, dynamic>> sendFriendRequest(
      Map<String, dynamic> data) async {
    final res = await _dio.post('/friends/request', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> respondToRequest(
      String requestId, Map<String, dynamic> data) async {
    final res = await _dio.patch('/friends/request/$requestId', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<void> removeFriend(String friendshipId) async {
    await _dio.delete('/friends/$friendshipId');
  }

  Future<void> blockUser(Map<String, dynamic> data) async {
    await _dio.post('/users/block', data: data);
  }

  // Groups

  Future<List<Map<String, dynamic>>> getGroups(String userId) async {
    final res = await _dio.get('/groups');
    return _list(res.data);
  }

  Future<Map<String, dynamic>> createGroup(Map<String, dynamic> data) async {
    final res = await _dio.post('/groups', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getGroupDetail(String groupId) async {
    final res = await _dio.get('/groups/$groupId');
    return res.data as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getGroupMembers(String groupId) async {
    final res = await _dio.get('/groups/$groupId/members');
    return _list(res.data);
  }

  /// The API's answer: `{status: 'pending'}` now that joining waits for an
  /// admin. An older server admitted immediately and sent no status.
  Future<Map<String, dynamic>> joinGroup(
      String inviteToken, String userId) async {
    final res = await _dio.post('/groups/join/$inviteToken');
    final data = res.data;
    return data is Map ? Map<String, dynamic>.from(data) : const {};
  }

  Future<void> leaveGroup(String groupId, String userId) async {
    await _dio.delete('/groups/$groupId/members/$userId');
  }

  Future<void> removeMember(String groupId, String userId) async {
    await _dio.delete('/groups/$groupId/members/$userId');
  }

  Future<Map<String, dynamic>> generateInviteLink(String groupId) async {
    final res = await _dio.post('/groups/$groupId/invite');
    return res.data as Map<String, dynamic>;
  }

  // Join requests — reviewed by the group's owner or admins.

  Future<List<Map<String, dynamic>>> getJoinRequests(String groupId) async {
    final res = await _dio.get('/groups/$groupId/requests');
    return _list(res.data);
  }

  // An empty object rather than no body: Fastify rejects a JSON POST whose
  // body is missing outright.
  Future<void> approveJoinRequest(String groupId, String requestId) async {
    await _dio.post('/groups/$groupId/requests/$requestId/approve',
        data: const <String, dynamic>{});
  }

  Future<void> rejectJoinRequest(String groupId, String requestId) async {
    await _dio.post('/groups/$groupId/requests/$requestId/reject',
        data: const <String, dynamic>{});
  }

  // Invites — an owner or admin asks someone in; they accept or decline.

  /// `{status: 'invited'}`, or `{status: 'member'}` when the person had already
  /// asked to join and was let straight in.
  Future<Map<String, dynamic>> inviteToGroup(
      String groupId, Map<String, dynamic> target) async {
    final res = await _dio.post('/groups/$groupId/invites', data: target);
    final data = res.data;
    return data is Map ? Map<String, dynamic>.from(data) : const {};
  }

  Future<List<Map<String, dynamic>>> getGroupInvites(String groupId) async {
    final res = await _dio.get('/groups/$groupId/invites');
    return _list(res.data);
  }

  Future<void> cancelInvite(String groupId, String inviteId) async {
    await _dio.delete('/groups/$groupId/invites/$inviteId');
  }

  Future<List<Map<String, dynamic>>> getMyInvites() async {
    final res = await _dio.get('/groups/invites');
    return _list(res.data);
  }

  Future<void> acceptInvite(String inviteId) async {
    await _dio.post('/groups/invites/$inviteId/accept',
        data: const <String, dynamic>{});
  }

  Future<void> declineInvite(String inviteId) async {
    await _dio.post('/groups/invites/$inviteId/decline',
        data: const <String, dynamic>{});
  }
}
