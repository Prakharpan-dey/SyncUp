import 'package:equatable/equatable.dart';

/// One signed-in device.
///
/// Sessions are grouped by `sessionId` rather than by refresh token: rotation
/// mints a new token every 15 minutes, so listing tokens would show the same
/// device over and over.
class AuthSession extends Equatable {
  final String sessionId;

  /// Best-effort device name from the server. Null when the client that signed
  /// in did not send one.
  final String? deviceLabel;

  final DateTime signedInAt;

  /// True for the device viewing the list — it must not offer to sign itself
  /// out from here, since that is what the Log Out button is for.
  final bool isCurrent;

  const AuthSession({
    required this.sessionId,
    required this.deviceLabel,
    required this.signedInAt,
    required this.isCurrent,
  });

  @override
  List<Object?> get props => [sessionId, deviceLabel, signedInAt, isCurrent];
}
