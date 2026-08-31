import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'notification_service.dart';

/// Handles the notification permission flow:
/// - Permission is requested only after the first meaningful action
///   (task completion or attendance log), NOT on cold launch
/// - If denied, enables an in-app banner with OS settings link
class NotificationPermissionHandler {
  final FlutterSecureStorage _storage;
  final NotificationService _notificationService;

  /// Runs after permission is granted, to register this device for push.
  ///
  /// Injected as a callback rather than a `PushService` dependency: that
  /// service reaches the auth repository, which would make this a cycle.
  final Future<void> Function()? _onGranted;

  static const _keyFirstAction = 'has_completed_first_action';
  static const _keyPermissionAsked = 'notification_permission_asked';
  static const _keyPermissionGranted = 'notification_permission_granted';

  NotificationPermissionHandler(
    this._storage,
    this._notificationService, [
    this._onGranted,
  ]);

  /// Check if we should show the permission request
  Future<bool> shouldRequestPermission() async {
    final firstAction = await _storage.read(key: _keyFirstAction);
    final asked = await _storage.read(key: _keyPermissionAsked);
    return firstAction == 'true' && asked != 'true';
  }

  /// Check if permission was denied (for showing in-app banner)
  Future<bool> wasPermissionDenied() async {
    final asked = await _storage.read(key: _keyPermissionAsked);
    final granted = await _storage.read(key: _keyPermissionGranted);
    return asked == 'true' && granted != 'true';
  }

  /// Called when user completes their first meaningful action
  /// (task completion or attendance log)
  Future<void> onFirstMeaningfulAction(BuildContext context) async {
    await _storage.write(key: _keyFirstAction, value: 'true');

    if (await shouldRequestPermission()) {
      if (context.mounted) {
        await _showPermissionDialog(context);
      }
    }
  }

  /// Show explanatory dialog before requesting OS permission
  Future<void> _showPermissionDialog(BuildContext context) async {
    final shouldRequest = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.notifications_rounded,
            size: 48, color: Color(0xFF6C5CE7)),
        title: const Text('Stay on Track'),
        content: const Text(
          'Get timely reminders for upcoming tasks, attendance warnings, '
          'and social updates from your friends.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not Now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Enable Notifications'),
          ),
        ],
      ),
    );

    await _storage.write(key: _keyPermissionAsked, value: 'true');

    if (shouldRequest == true) {
      await _grantAndRegister();
    }
  }

  /// Manually request permission again (from settings/banner)
  Future<bool> requestPermissionManually() async {
    final granted = await _grantAndRegister();
    await _storage.write(key: _keyPermissionAsked, value: 'true');
    return granted;
  }

  /// Requests OS permission and, if granted, registers for push.
  ///
  /// Without the registration step the app would be allowed to show
  /// notifications but the server would have no token to send them to.
  Future<bool> _grantAndRegister() async {
    final granted = await _notificationService.requestPermission();
    await _storage.write(key: _keyPermissionGranted, value: granted.toString());
    if (granted) await _onGranted?.call();
    return granted;
  }
}
