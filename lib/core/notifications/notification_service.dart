import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../theme/app_colors.dart';

/// The one channel SyncUp posts on, shared by local notifications and by the
/// pushes FCM draws itself.
///
/// Must match `com.google.firebase.messaging.default_notification_channel_id`
/// in AndroidManifest.xml. If the two drift apart, backgrounded pushes land on
/// a separate system-generated channel and the user sees two SyncUp entries in
/// notification settings.
const _channelId = 'syncup_default';

/// How every SyncUp notification is presented.
///
/// Hoisted to file level so an immediate notification and a scheduled reminder
/// are identical — when this lived inline, only one of the two could change.
const _androidDetails = AndroidNotificationDetails(
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

    await _initializeTimeZone();

    _initialized = true;
  }

  /// Loads the timezone database and points `tz.local` at the device's zone.
  ///
  /// Without this `tz.local` stays UTC, and every scheduled reminder would fire
  /// off by the device offset — 5.5 hours out in IST. The fallback builds a
  /// fixed-offset zone, which is right today but wrong across a DST boundary;
  /// it exists only so a failure here degrades rather than misfires wildly.
  Future<void> _initializeTimeZone() async {
    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation(await FlutterTimezone.getLocalTimezone()));
    } catch (_) {
      final offset = DateTime.now().timeZoneOffset;
      tz.setLocalLocation(tz.Location(
        'local',
        [0],
        [0],
        [tz.TimeZone(offset, isDst: false, abbreviation: 'LOC')],
      ));
    }
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
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(android: _androidDetails),
      payload: payload,
    );
  }

  /// Schedules an exact one-shot notification at [when], a device-local time.
  ///
  /// Returns false when [when] has already passed: a notification scheduled in
  /// the past fires immediately, which is worse than not firing at all — the
  /// user gets a reminder for something already due.
  ///
  /// Deliberately one schedule per occurrence rather than a repeating
  /// `matchDateTimeComponents` notification: a repeat would fire on days
  /// outside the chosen weekdays, fire even once the task was ticked off, and
  /// could not be cancelled for a single day.
  Future<bool> scheduleAt({
    required int id,
    required DateTime when,
    required String title,
    required String body,
    String? payload,
  }) async {
    await initialize();
    if (!when.isAfter(DateTime.now())) return false;

    await _plugin.zonedSchedule(
      id: id,
      scheduledDate: tz.TZDateTime.from(when, tz.local),
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(android: _androidDetails),
      androidScheduleMode: await _scheduleMode(),
      payload: payload,
    );
    return true;
  }

  /// Exact where allowed, inexact where not.
  ///
  /// Android 14+ denies exact alarms to most apps by default. Downgrading keeps
  /// reminders working — they drift by minutes in Doze rather than vanishing.
  Future<AndroidScheduleMode> _scheduleMode() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return AndroidScheduleMode.exactAllowWhileIdle;
    final canBeExact = await android.canScheduleExactNotifications() ?? false;
    return canBeExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  /// Asks for the exact-alarm permission. No-op where it does not apply.
  Future<bool> requestExactAlarmPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;
    return await android.requestExactAlarmsPermission() ?? false;
  }

  /// Everything currently scheduled. The scheduler reconciles against this
  /// rather than keeping its own bookkeeping, so it self-heals.
  Future<List<PendingNotificationRequest>> pending() =>
      _plugin.pendingNotificationRequests();

  /// Cancel a scheduled notification
  Future<void> cancel(int id) async {
    await _plugin.cancel(id: id);
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
