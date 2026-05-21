import 'package:dio/dio.dart';

class AttendanceRemoteDataSource {
  final Dio _dio;
  AttendanceRemoteDataSource(this._dio);

  // --- Subjects ---

  Future<List<Map<String, dynamic>>> getSubjects(String userId) async {
    final res =
        await _dio.get('/subjects', queryParameters: {'user_id': userId});
    return List<Map<String, dynamic>>.from(res.data['subjects'] ?? []);
  }

  Future<Map<String, dynamic>> createSubject(
      Map<String, dynamic> data) async {
    final res = await _dio.post('/subjects', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateSubject(
      String subjectId, Map<String, dynamic> data) async {
    final res = await _dio.patch('/subjects/$subjectId', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<void> deleteSubject(String subjectId) async {
    await _dio.delete('/subjects/$subjectId');
  }

  // --- Sessions ---

  Future<List<Map<String, dynamic>>> getSessions(String subjectId) async {
    final res = await _dio.get('/subjects/$subjectId/sessions');
    return List<Map<String, dynamic>>.from(res.data['sessions'] ?? []);
  }

  Future<Map<String, dynamic>> logSession(
      String subjectId, Map<String, dynamic> data) async {
    final res = await _dio.post('/subjects/$subjectId/sessions', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<void> deleteSession(String subjectId, String sessionId) async {
    await _dio.delete('/subjects/$subjectId/sessions/$sessionId');
  }
}
