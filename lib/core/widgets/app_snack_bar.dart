import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// How long a message stays up.
///
/// Flutter's own default is already 4s, so a snackbar that appears to hang
/// around forever is almost always several of them queued behind each other:
/// `ScaffoldMessenger` shows them one at a time, and a run of them reads as one
/// that never leaves. [showAppSnackBar] clears the current message before
/// showing the next, which is what actually fixes that.
const _defaultDuration = Duration(seconds: 3);
const _errorDuration = Duration(seconds: 4);

/// Shows a message, replacing whatever is on screen rather than queueing.
///
/// Use this instead of `ScaffoldMessenger.of(context).showSnackBar` so every
/// message in the app dismisses on the same timing and a burst cannot stack up.
///
/// Returns the controller so a caller can await dismissal — the undo flow on
/// attendance uses it to know whether the user reached for Undo.
ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? showAppSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
  SnackBarAction? action,
  Duration? duration,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return null;
  return showAppSnackBarOn(
    messenger,
    message,
    isError: isError,
    action: action,
    duration: duration,
  );
}

/// As [showAppSnackBar], but against a messenger captured earlier.
///
/// Use this when the message follows an `await`: capture the messenger before
/// the gap so nothing reaches for a `BuildContext` that may no longer be
/// mounted by the time the call happens.
ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showAppSnackBarOn(
  ScaffoldMessengerState messenger,
  String message, {
  bool isError = false,
  SnackBarAction? action,
  Duration? duration,
}) {
  // Replacing rather than queueing: a burst of messages otherwise plays back
  // one after another and reads as a single one that never leaves.
  messenger.hideCurrentSnackBar();

  final effective = duration ?? (isError ? _errorDuration : _defaultDuration);

  final controller = messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      duration: effective,
      backgroundColor: isError ? AppColors.error : null,
      action: action,
    ),
  );

  // SnackBar's own auto-dismiss did not fire on device — messages stayed up
  // indefinitely, which is the bug being fixed here. Its internal timer is
  // started off the entrance animation and is sensitive to platform animation
  // and accessibility settings, so dismissal is driven explicitly instead.
  //
  // `closed` completes if the message is replaced or actioned first, in which
  // case this timer must not hide whatever took its place.
  var alreadyClosed = false;
  unawaited(controller.closed.then((_) => alreadyClosed = true));
  Timer(effective, () {
    if (!alreadyClosed) messenger.hideCurrentSnackBar();
  });

  return controller;
}
