import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String username;
  final String displayName;
  final String email;
  final DateTime? emailVerifiedAt;
  final String? photoUrl;
  final String? college;
  final String? department;
  final int? semester;
  final int? graduationYear;
  final String privacySearchable;
  final String privacySharingDefault;

  /// Per-category push toggles, e.g. `{'task_reminders': true}`.
  ///
  /// Stored server-side as a single `notification_settings` JSON object rather
  /// than one column per category, so new categories need no migration.
  final Map<String, bool> notificationSettings;

  const User({
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

  /// Whether [category] is on, treating an absent key as enabled — a user who
  /// has never opened the preferences screen should still get notifications.
  bool notificationEnabled(String category) =>
      notificationSettings[category] ?? true;

  bool get isEmailVerified => emailVerifiedAt != null;

  @override
  List<Object?> get props => [id, username, email];
}
