import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../theme/app_colors.dart';

/// The one channel SyncUp posts on, shared by local notifications and by the
/// pushes FCM draws itself.
///
/// Must match `com.google.firebase.messaging.default_notification_channel_id`
/// in AndroidManifest.xml. If the two drift apart, backgrounded pushes land on
/// a separate system-generated channel and the user sees two SyncUp entries in
/// notification settings.
const _channelId = 'syncup_default';

/// Core notification service wrapping flutter_local_notifications
/// Can be extended with FCM once Firebase is fully configured
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Invoked with a notification's payload when the user taps it.
  ///
  /// Set by PushService, which owns the router. Kept as a callback rather than
  /// a direct navigation call so this service stays free of app dependencies.
  void Function(String route)? onDeepLink;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@drawable/ic_stat_syncup');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Created up front, not on first post: FCM only files a backgrounded push
    // on this channel if it already exists, and the first push can easily
    // arrive before the app has ever shown a local notification.
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            'SyncUp Notifications',
            description: 'Task reminders, attendance warnings, and friend activity',
            importance: Importance.high,
          ),
        );

    _initialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    onDeepLink?.call(payload);
  }

  /// Request notification permission (Android 13+, iOS)
  Future<bool> requestPermission() async {
    // Android 13+
    final androidImpl =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      final granted = await androidImpl.requestNotificationsPermission();
      return granted ?? false;
    }

    // iOS
    final iosImpl =
        _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (iosImpl != null) {
      final granted = await iosImpl.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true; // Default allow on other platforms
  }

  /// Show an immediate local notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      'SyncUp Notifications',
      channelDescription:
          'Task reminders, attendance warnings, and friend activity',
      importance: Importance.high,
      priority: Priority.high,
      // Matches the accent FCM applies to pushes it draws itself, so a
      // foreground notification and a backgrounded one look the same.
      color: AppColors.primary,
    );

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(android: androidDetails),
      payload: payload,
    );
  }

  /// Cancel a scheduled notification
  Future<void> cancel(int id) async {
    await _plugin.cancel(id: id);
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
