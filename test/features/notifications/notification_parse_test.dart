import 'package:flutter_test/flutter_test.dart';
import 'package:syncup/features/notifications/data/datasources/notification_remote_datasource.dart';

void main() {
  final item = {
    'id': 'n1',
    'type': 'friend_request',
    'title': 'New friend request',
    'is_read': false,
    'created_at': '2026-09-13T05:46:23.470Z',
  };

  group('reading the notifications list', () {
    /// The bug: the API sends a bare array, and the app read
    /// `data['notifications']` — which throws on a list — so the bell page
    /// always said "no notifications yet".
    test('reads the bare array the API sends', () {
      expect(parseNotificationList([item]), [item]);
    });

    test('still reads a list wrapped in {notifications: [...]}', () {
      expect(parseNotificationList({'notifications': [item]}), [item]);
    });

    test('is empty, not an error, for anything else', () {
      expect(parseNotificationList(null), isEmpty);
      expect(parseNotificationList({'unexpected': true}), isEmpty);
      expect(parseNotificationList(['not a map']), isEmpty);
    });
  });
}
