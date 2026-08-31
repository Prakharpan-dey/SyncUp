import 'package:flutter_test/flutter_test.dart';
import 'package:syncup/core/utils/validators.dart';

void main() {
  group('email', () {
    test('accepts an ordinary address', () {
      expect(Validators.email('someone@example.com'), isNull);
    });
    test('rejects a missing address', () {
      expect(Validators.email(null), isNotNull);
      expect(Validators.email(''), isNotNull);
    });
    test('rejects an address with no domain', () {
      expect(Validators.email('someone@'), isNotNull);
    });
    test('rejects an address with no @', () {
      expect(Validators.email('someone.example.com'), isNotNull);
    });
  });

  group('password', () {
    test('accepts eight characters', () {
      expect(Validators.password('abcd1234'), isNull);
    });
    test('rejects seven', () {
      expect(Validators.password('abcd123'), isNotNull);
    });
    test('rejects empty', () {
      expect(Validators.password(''), isNotNull);
    });
  });

  group('username', () {
    test('accepts letters, digits and underscores', () {
      expect(Validators.username('rhea_menon2026'), isNull);
    });
    test('rejects fewer than three characters', () {
      expect(Validators.username('ab'), isNotNull);
    });
    // Mirrors the server's character set, so the user is told before a round trip.
    test('rejects punctuation the server would reject', () {
      expect(Validators.username('rhea.menon'), isNotNull);
      expect(Validators.username('rhea menon'), isNotNull);
    });
  });

  group('displayName', () {
    test('accepts a name', () {
      expect(Validators.displayName('Rhea Menon'), isNull);
    });
    test('rejects blank', () {
      expect(Validators.displayName(''), isNotNull);
      expect(Validators.displayName(null), isNotNull);
    });
  });

  group('taskTitle', () {
    test('accepts a title', () {
      expect(Validators.taskTitle('Finish DBMS assignment'), isNull);
    });
    test('rejects blank', () {
      expect(Validators.taskTitle(''), isNotNull);
    });
  });
}
