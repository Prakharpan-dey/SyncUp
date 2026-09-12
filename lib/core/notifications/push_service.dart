import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/di/auth_providers.dart';
import '../../features/social/presentation/viewmodels/social_viewmodel.dart';
import '../auth/current_user.dart';
import '../router/app_router.dart';
import 'notification_service.dart';

/// Handles a push that arrives while the app is terminated or backgrounded.
///
/// Must be a top-level function: Android runs it in a separate isolate with a
/// fresh Dart context, so nothing from the app's state is available here.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  // The system tray notification is drawn by FCM itself for `notification`
  // payloads, so there is deliberately nothing to do — this handler exists so
  // the isolate has a registered entry point and data payloads are not dropped.
  debugPrint('Background push: ${message.messageId}');
}

/// This install's FCM token, or null when Firebase is unavailable.
///
/// Standalone rather than a [PushService] method so callers that must not
/// depend on the service — the auth repository, which [PushService] itself
/// depends on — can reach it without creating a cycle.
Future<String?> currentPushToken() async {
  if (Firebase.apps.isEmpty) return null;
  try {
    return await FirebaseMessaging.instance.getToken();
  } catch (e) {
    debugPrint('Push: could not read token: $e');
    return null;
  }
}

/// Connects Firebase Cloud Messaging to the account's device registry.
///
/// The token identifies this install to FCM. It is registered against the
/// signed-in account via `POST /auth/devices`, which claims it — so a token
/// belongs to exactly one account and moves when someone else signs in on the
/// same handset.
class PushService {
  final Ref _ref;

  StreamSubscription<String>? _tokenRefresh;
  StreamSubscription<RemoteMessage>? _foreground;
  StreamSubscription<RemoteMessage>? _opened;
  bool _started = false;

  PushService(this._ref);

  bool get _firebaseAvailable => Firebase.apps.isNotEmpty;

  /// Registers this device and starts listening for messages.
  ///
  /// Call after sign-in. Safe to call repeatedly — later calls are no-ops.
  Future<void> start() async {
    if (_started || !_firebaseAvailable) return;
    _started = true;

    try {
      final messaging = FirebaseMessaging.instance;

      // Permission is requested separately and deliberately later (see
      // NotificationPermissionHandler); asking here would mean a system prompt
      // on first launch, which users reliably decline.
      final settings = await messaging.getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
        debugPrint('Push: permission not yet requested, deferring registration');
        _started = false;
        return;
      }
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('Push: permission denied, skipping registration');
        return;
      }

      await _registerCurrentToken(messaging);

      // FCM rotates tokens on reinstall, restore, and occasionally on its own.
      // Without this the server would keep pushing to a dead token.
      _tokenRefresh = messaging.onTokenRefresh.listen(
        _registerToken,
        onError: (Object e) => debugPrint('Push: token refresh failed: $e'),
      );

      // A foreground push does not raise a system notification on its own, so
      // it is drawn locally to match the backgrounded experience.
      _foreground = FirebaseMessaging.onMessage.listen(_showForeground);

      // Tapping one of those locally drawn notifications comes back here.
      NotificationService().onDeepLink = _navigate;

      // Tapping a push that FCM drew while the app was backgrounded.
      _opened = FirebaseMessaging.onMessageOpenedApp.listen(_openMessage);

      // The app was launched from a push, so no stream ever fires for it.
      // Without this, tapping a notification on a killed app drops the user on
      // the home screen with no sign of what they tapped.
      final initial = await messaging.getInitialMessage();
      if (initial != null) _openMessage(initial);
    } catch (e) {
      debugPrint('Push: setup failed: $e');
      _started = false;
    }
  }

  /// Whether the OS currently allows notifications for this app.
  ///
  /// Every in-app preference is moot if this is false, so the preferences
  /// screen reads it to say so rather than presenting switches that cannot
  /// take effect.
  Future<AuthorizationStatus> permissionStatus() async {
    if (!_firebaseAvailable) return AuthorizationStatus.notDetermined;
    try {
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      return settings.authorizationStatus;
    } catch (e) {
      debugPrint('Push: could not read permission status: $e');
      return AuthorizationStatus.notDetermined;
    }
  }

  /// Requests permission, then registers. Returns whether push is now allowed.
  Future<bool> requestPermissionAndRegister() async {
    if (!_firebaseAvailable) return false;

    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      final granted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;

      if (granted) {
        _started = false; // let start() run its listeners now that we may push
        await start();
      }
      return granted;
    } catch (e) {
      debugPrint('Push: permission request failed: $e');
      return false;
    }
  }

  Future<void> _registerCurrentToken(FirebaseMessaging messaging) async {
    final token = await messaging.getToken();
    if (token == null) {
      debugPrint('Push: no FCM token available');
      return;
    }
    await _registerToken(token);
  }

  Future<void> _registerToken(String token) async {
    try {
      await _ref.read(authRepositoryProvider).registerDevice(
            fcmToken: token,
            platform: _platform,
          );
      debugPrint('Push: device registered');
    } catch (e) {
      // Not fatal — the user simply will not receive pushes on this device.
      debugPrint('Push: could not register device: $e');
    }
  }

  String get _platform {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    return 'android';
  }

  void _openMessage(RemoteMessage message) {
    final link = message.data['deep_link'];
    if (link is String) _navigate(link);
  }

  /// Sends the user to a route named by a notification.
  ///
  /// Routes come from the server, so they are checked before use — go_router
  /// throws on anything that is not a location, and a malformed payload should
  /// not be able to crash the app on notification tap.
  void _navigate(String route) {
    if (!route.startsWith('/')) {
      debugPrint('Push: ignoring non-route deep link "$route"');
      return;
    }
    // Redirects handle the signed-out and unverified cases, stashing the
    // destination until the user is allowed to reach it.
    _ref.read(appRouterProvider).go(route);
    _refreshFor(route);
  }

  /// Brings the screen a push is about up to date.
  ///
  /// Going to a route that is already on screen does not rebuild it, so a
  /// friend request that arrived — or was tapped — while the Friends screen
  /// was open used to leave it saying "no pending requests".
  void _refreshFor(String? route) {
    if (route == null) return;
    final social = _ref.read(socialViewModelProvider.notifier);
    if (route.startsWith('/feed/friends')) {
      social.loadPendingRequests(_ref.read(currentUserIdProvider));
      return;
    }
    if (route == '/feed/groups') {
      // Where invites are listed — someone just invited you into a group.
      social.loadMyInvites();
      return;
    }
    const groupPrefix = '/feed/groups/';
    if (route.startsWith(groupPrefix)) {
      // Someone joined, or you were let in: the list's member counts and
      // the groups in it may both have changed.
      social.loadGroups(_ref.read(currentUserIdProvider));
      final groupId = route.substring(groupPrefix.length).split('/').first;
      // Only the group already on screen: reloading another would swap what
      // an open detail view is showing.
      if (_ref.read(socialViewModelProvider).selectedGroup?.id == groupId) {
        social.loadGroupDetail(groupId);
      }
    }
  }

  Future<void> _showForeground(RemoteMessage message) async {
    _refreshFor(message.data['deep_link'] as String?);
    final notification = message.notification;
    if (notification == null) return;

    await NotificationService().initialize();
    await NotificationService().showNotification(
      // Notification ids are 32-bit; hashCode can exceed that.
      id: message.messageId.hashCode & 0x7FFFFFFF,
      title: notification.title ?? 'SyncUp',
      body: notification.body ?? '',
      payload: message.data['deep_link'] as String?,
    );
  }

  void dispose() {
    _tokenRefresh?.cancel();
    _foreground?.cancel();
    _opened?.cancel();
    NotificationService().onDeepLink = null;
    _started = false;
  }
}

final pushServiceProvider = Provider<PushService>((ref) {
  final service = PushService(ref);
  ref.onDispose(service.dispose);
  return service;
});
