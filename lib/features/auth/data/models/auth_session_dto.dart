import '../../domain/entities/auth_session.dart';

class AuthSessionDto {
  final String sessionId;
  final String? deviceLabel;
  final String signedInAt;
  final bool isCurrent;

  const AuthSessionDto({
    required this.sessionId,
    required this.deviceLabel,
    required this.signedInAt,
    required this.isCurrent,
  });

  factory AuthSessionDto.fromJson(Map<String, dynamic> json) => AuthSessionDto(
        sessionId: json['session_id'] as String,
        deviceLabel: json['device_label'] as String?,
        signedInAt: json['signed_in_at'] as String,
        isCurrent: json['is_current'] == true,
      );

  AuthSession toDomain() => AuthSession(
        sessionId: sessionId,
        deviceLabel: deviceLabel,
        // Server sends UTC; render in the viewer's own timezone.
        signedInAt: DateTime.parse(signedInAt).toLocal(),
        isCurrent: isCurrent,
      );
}
