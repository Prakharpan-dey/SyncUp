import 'package:dio/dio.dart';

class TaskRemoteDataSource {
  final Dio _dio;
  TaskRemoteDataSource(this._dio);

  Future<List<Map<String, dynamic>>> getTasks(String userId) async {
    final res = await _dio.get('/tasks', queryParameters: {'user_id': userId});
    return List<Map<String, dynamic>>.from(res.data['tasks'] ?? []);
  }

  Future<Map<String, dynamic>> createTask(Map<String, dynamic> data) async {
    final res = await _dio.post('/tasks', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateTask(
    String taskId,
    Map<String, dynamic> data,
  ) async {
    final res = await _dio.patch('/tasks/$taskId', data: data);
    return res.data as Map<String, dynamic>;
  }

  /// Flips a task between pending and completed.
  ///
  /// A dedicated endpoint rather than a PATCH: `updateTaskSchema` has no
  /// `status` field, so Zod stripped it and the completion never reached the
  /// server — which is also what stopped completions from ever publishing to
  /// the feed. The empty body is required; the route rejects a POST with none.
  Future<Map<String, dynamic>> toggleTask(String taskId) async {
    final res = await _dio.post('/tasks/$taskId/toggle', data: const {});
    return res.data as Map<String, dynamic>;
  }

  Future<void> deleteTask(String taskId) async {
    await _dio.delete('/tasks/$taskId');
  }
}
