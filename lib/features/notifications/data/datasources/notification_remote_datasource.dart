import 'package:dio/dio.dart';

class NotificationRemoteDataSource {
  final Dio _dio;
  NotificationRemoteDataSource(this._dio);

  Future<List<Map<String, dynamic>>> getNotifications() async {
    final res = await _dio.get('/notifications');
    return List<Map<String, dynamic>>.from(res.data['notifications'] ?? []);
  }

  Future<void> markAsRead(String notificationId) async {
    await _dio.patch('/notifications/$notificationId/read');
  }

  Future<void> markAllAsRead() async {
    await _dio.patch('/notifications/read-all');
  }

  Future<int> getUnreadCount() async {
    final res = await _dio.get('/notifications/unread-count');
    return res.data['count'] ?? 0;
  }
}
