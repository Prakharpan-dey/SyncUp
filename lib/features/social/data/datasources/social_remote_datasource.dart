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

  Future<void> joinGroup(String inviteToken, String userId) async {
    await _dio.post('/groups/join/$inviteToken');
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
}
