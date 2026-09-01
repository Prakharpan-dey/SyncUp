import '../../domain/entities/user.dart';

class UserDto {
  final String id;
  final String username;
  final String displayName;
  final String email;
  final String? emailVerifiedAt;
  final String? photoUrl;
  final String? college;
  final String? department;
  final int? semester;
  final int? graduationYear;
  final String privacySearchable;
  final String privacySharingDefault;
  final Map<String, bool> notificationSettings;

  const UserDto({
    required this.id,
    required this.username,
    required this.displayName,
    required this.email,
    this.emailVerifiedAt,
    this.photoUrl,
    this.college,
    this.department,
    this.semester,
    this.graduationYear,
    this.privacySearchable = 'everyone',
    this.privacySharingDefault = 'summary',
    this.notificationSettings = const {},
  });

  factory UserDto.fromJson(Map<String, dynamic> json) => UserDto(
    id: json['id'] as String,
    username: json['username'] as String,
    displayName: json['display_name'] as String,
    email: json['email'] as String,
    emailVerifiedAt: json['email_verified_at'] as String?,
    photoUrl: json['photo_url'] as String?,
    college: json['college'] as String?,
    department: json['department'] as String?,
    semester: json['semester'] as int?,
    graduationYear: json['graduation_year'] as int?,
    privacySearchable: json['privacy_searchable'] as String? ?? 'everyone',
    privacySharingDefault:
        json['privacy_sharing_default'] as String? ?? 'summary',
    // Sent as a JSON object; a value that is not a bool is dropped rather than
    // crashing the parse, since one bad key must not cost the whole user.
    notificationSettings: switch (json['notification_settings']) {
      final Map<String, dynamic> m => {
          for (final e in m.entries)
            if (e.value is bool) e.key: e.value as bool,
        },
      _ => const <String, bool>{},
    },
  );

  User toDomain() => User(
    id: id,
    username: username,
    displayName: displayName,
    email: email,
    emailVerifiedAt: emailVerifiedAt != null
        ? DateTime.parse(emailVerifiedAt!)
        : null,
    photoUrl: photoUrl,
    college: college,
    department: department,
    semester: semester,
    graduationYear: graduationYear,
    privacySearchable: privacySearchable,
    privacySharingDefault: privacySharingDefault,
    notificationSettings: notificationSettings,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'display_name': displayName,
    'email': email,
    'email_verified_at': emailVerifiedAt,
    'photo_url': photoUrl,
    'college': college,
    'department': department,
    'semester': semester,
    'graduation_year': graduationYear,
    'privacy_searchable': privacySearchable,
    'privacy_sharing_default': privacySharingDefault,
    'notification_settings': notificationSettings,
  };
}
