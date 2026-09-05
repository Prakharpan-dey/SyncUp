import 'package:dio/dio.dart';

class TaskSeriesRemoteDataSource {
  final Dio _dio;
  TaskSeriesRemoteDataSource(this._dio);

  Future<List<Map<String, dynamic>>> getSeries() async {
    final res = await _dio.get('/task-series');
    return List<Map<String, dynamic>>.from(res.data ?? []);
  }

  Future<Map<String, dynamic>> createSeries(Map<String, dynamic> data) async {
    final res = await _dio.post('/task-series', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateSeries(
    String seriesId,
    Map<String, dynamic> data,
  ) async {
    final res = await _dio.patch('/task-series/$seriesId', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<void> deleteSeries(String seriesId) async {
    await _dio.delete('/task-series/$seriesId');
  }
}
