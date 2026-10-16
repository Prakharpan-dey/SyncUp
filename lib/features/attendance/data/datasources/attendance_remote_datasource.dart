import 'package:dio/dio.dart';

class AttendanceRemoteDataSource {
  final Dio _dio;
  AttendanceRemoteDataSource(this._dio);

  /// The API answers list requests with a bare JSON array. These used to read
  /// `res.data['subjects']` / `['sessions']`, an envelope that does not exist,
  /// so any read from the server came back empty.
  static List<Map<String, dynamic>> _list(dynamic data) {
    if (data is! List) return const [];
    return data.whereType<Map>().map(Map<String, dynamic>.from).toList();
  }

  // --- Subjects ---

  Future<List<Map<String, dynamic>>> getSubjects(String userId) async {
    // The account comes from the token; the server ignores any user_id.
    final res = await _dio.get('/subjects');
    return _list(res.data);
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
    return _list(res.data);
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
