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
  });

  bool get isEmailVerified => emailVerifiedAt != null;

  @override
  List<Object?> get props => [id, username, email];
}
