import 'package:dio/dio.dart';

class FeedRemoteDataSource {
  final Dio _dio;
  FeedRemoteDataSource(this._dio);

  /// Cursor-based feed retrieval
  Future<Map<String, dynamic>> getFeed({
    required String tab,
    String? cursor,
    int limit = 20,
  }) async {
    final params = <String, dynamic>{
      'tab': tab,
      'limit': limit,
    };
    if (cursor != null) params['cursor'] = cursor;

    final res = await _dio.get('/feed', queryParameters: params);
    return res.data as Map<String, dynamic>;
  }

  /// Toggles this user's reaction. Returns the server's resulting state.
  Future<Map<String, dynamic>> react(String feedItemId, String emoji) async {
    final res =
        await _dio.post('/feed/$feedItemId/react', data: {'emoji': emoji});
    return Map<String, dynamic>.from(res.data as Map);
  }
}
