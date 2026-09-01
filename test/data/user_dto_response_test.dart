import 'package:flutter_test/flutter_test.dart';
import 'package:syncup/features/auth/data/models/user_dto.dart';

/// The API is inconsistent about wrapping: `/auth/login` and `/auth/me` return
/// `{user: {...}}`, while `PATCH /users/me` returns the user object directly.
/// Reading `data['user']` unconditionally made every profile save throw a
/// null-to-Map cast error *after* the server had already committed the
/// change — the write landed, the response parse did not.
void main() {
  final bareUser = <String, dynamic>{
    'id': 'aaaaaaaa-0000-0000-0000-000000000001',
    'username': 'refinetest2026',
    'display_name': 'Refine Test',
    'email': 'refinetest2026@example.com',
    'email_verified_at': null,
    'photo_url': null,
    'college': 'NIT Hamirpur',
    'department': null,
    'semester': null,
    'graduation_year': null,
    'privacy_searchable': 'everyone',
    'privacy_sharing_default': 'summary',
    'notification_settings': {'reactions': false, 'daily_digest': true},
  };

  group('UserDto parses either response shape', () {
    test('a bare user object, as PATCH /users/me returns', () {
      final user = UserDto.fromJson(bareUser).toDomain();
      expect(user.username, 'refinetest2026');
      expect(user.college, 'NIT Hamirpur');
    });

    test('the wrapped form, as /auth/me returns', () {
      final wrapped = <String, dynamic>{'user': bareUser};
      // Mirrors the repository's unwrap.
      final json = wrapped['user'] as Map<String, dynamic>? ?? wrapped;
      expect(UserDto.fromJson(json).toDomain().username, 'refinetest2026');
    });
  });

  group('notification settings round-trip', () {
    test('reads the saved per-category toggles', () {
      final user = UserDto.fromJson(bareUser).toDomain();
      expect(user.notificationEnabled('reactions'), isFalse);
      expect(user.notificationEnabled('daily_digest'), isTrue);
    });

    test('an absent category counts as enabled', () {
      final user = UserDto.fromJson(bareUser).toDomain();
      // Someone who has never opened the screen should still get notified.
      expect(user.notificationEnabled('task_reminders'), isTrue);
    });

    test('a missing settings object does not break parsing', () {
      final user = UserDto.fromJson({...bareUser, 'notification_settings': null})
          .toDomain();
      expect(user.notificationSettings, isEmpty);
      expect(user.notificationEnabled('reactions'), isTrue);
    });

    test('a non-bool value is dropped rather than crashing the parse', () {
      final user = UserDto.fromJson({
        ...bareUser,
        'notification_settings': {'reactions': 'yes', 'daily_digest': true},
      }).toDomain();
      expect(user.notificationSettings.containsKey('reactions'), isFalse);
      expect(user.notificationEnabled('daily_digest'), isTrue);
    });
  });
}
