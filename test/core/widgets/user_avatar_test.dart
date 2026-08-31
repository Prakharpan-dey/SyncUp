import 'package:flutter_test/flutter_test.dart';
import 'package:syncup/core/widgets/user_avatar.dart';

void main() {
  group('UserAvatar colour is deterministic', () {
    test('the same seed always yields the same colour', () {
      const id = '8f14e45f-ea4c-4b4a-9a1a-1c2d3e4f5a6b';
      expect(UserAvatar.colorFor(id), UserAvatar.colorFor(id));
    });

    // Keyed on the user id, not the name, so renaming yourself must not
    // reshuffle your avatar.
    test('different seeds generally differ', () {
      final colours = List.generate(
        40,
        (i) => UserAvatar.colorFor('user-$i'),
      ).toSet();
      expect(colours.length, greaterThan(3));
    });

    test('an empty seed still resolves rather than throwing', () {
      expect(() => UserAvatar.colorFor(''), returnsNormally);
    });
  });

  group('UserAvatar initials', () {
    test('takes first and last initial of a full name', () {
      expect(UserAvatar.initialsFor('Alex Dsouza'), 'AD');
    });

    test('takes one letter from a single name', () {
      expect(UserAvatar.initialsFor('Prakhar'), 'P');
    });

    test('skips the middle name rather than crowding the box', () {
      expect(UserAvatar.initialsFor('Ada Byron Lovelace'), 'AL');
    });

    test('tolerates extra whitespace', () {
      expect(UserAvatar.initialsFor('  Rhea   Menon  '), 'RM');
    });

    test('falls back for an empty name', () {
      expect(UserAvatar.initialsFor(''), '?');
      expect(UserAvatar.initialsFor('   '), '?');
    });

    test('uppercases lowercase input', () {
      expect(UserAvatar.initialsFor('arjun singh'), 'AS');
    });
  });
}
