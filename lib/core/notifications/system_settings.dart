import 'package:flutter/services.dart';

const _channel = MethodChannel('app.syncup.mobile/settings');

/// Opens SyncUp's notification settings in the system Settings app.
///
/// Android shows the notification permission prompt only so many times; after
/// "Don't allow" a request returns at once without asking. This page is the
/// one place the user can still turn notifications on.
Future<void> openNotificationSettings() async {
  try {
    await _channel.invokeMethod<void>('openNotificationSettings');
  } on PlatformException {
    // Nothing more to offer; the notice on screen still explains the state.
  } on MissingPluginException {
    // Not on Android (or in a test): nothing to open.
  }
}
