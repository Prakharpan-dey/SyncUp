import 'package:dio/dio.dart';

class NotificationRemoteDataSource {
  final Dio _dio;
  NotificationRemoteDataSource(this._dio);

  /// The API answers with a bare array. This read `res.data['notifications']`,
  /// which throws on a list — so the bell page stayed on "no notifications"
  /// however many there were. A wrapped `{notifications: [...]}` is still
  /// accepted, so either shape works.
  Future<List<Map<String, dynamic>>> getNotifications() async {
    final res = await _dio.get('/notifications');
    return parseNotificationList(res.data);
  }

  Future<void> markAsRead(String notificationId) async {
    await _dio.patch('/notifications/$notificationId/read');
  }

  Future<void> markAllAsRead() async {
    await _dio.patch('/notifications/read-all');
  }

  Future<void> deleteNotification(String notificationId) async {
    await _dio.delete('/notifications/$notificationId');
  }

  Future<void> clearAll() async {
    await _dio.delete('/notifications');
  }

  Future<int> getUnreadCount() async {
    final res = await _dio.get('/notifications/unread-count');
    return res.data['count'] ?? 0;
  }
}

/// Accepts the API's bare array, or the list inside `{notifications: [...]}`.
List<Map<String, dynamic>> parseNotificationList(Object? data) {
  final list = data is List
      ? data
      : data is Map && data['notifications'] is List
          ? data['notifications'] as List
          : const [];
  return [
    for (final item in list)
      if (item is Map) Map<String, dynamic>.from(item),
  ];
}
