import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncup/core/error/error_mapper.dart';
import 'package:syncup/core/error/failures.dart';

DioException _badResponse(int status, dynamic body) => DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: DioExceptionType.badResponse,
      response: Response<dynamic>(
        requestOptions: RequestOptions(path: '/x'),
        statusCode: status,
        data: body,
      ),
    );

void main() {
  group('ErrorMapper field errors', () {
    test('a conflict naming a field attaches it to that field', () {
      final f = ErrorMapper.fromDioException(_badResponse(409, {
        'message': 'Username already taken',
        'code': 'CONFLICT',
        'field': 'username',
      }));
      expect(f.fieldErrors, {'username': 'Username already taken'});
      expect(f.message, 'Username already taken');
      expect(f.statusCode, 409);
    });

    test('a 422 spreads its errors map across fields', () {
      final f = ErrorMapper.fromDioException(_badResponse(422, {
        'message': 'Validation error',
        'errors': {
          'username': ['Too short', 'Reserved'],
          'email': ['Invalid email'],
        },
      }));
      expect(f, isA<ValidationFailure>());
      expect(f.fieldErrors['username'], 'Too short, Reserved');
      expect(f.fieldErrors['email'], 'Invalid email');
    });

    test('an unattributed error leaves fields clean', () {
      final f = ErrorMapper.fromDioException(
          _badResponse(401, {'message': 'Invalid credentials'}));
      expect(f.fieldErrors, isEmpty);
      expect(f.message, 'Invalid credentials');
    });
  });

  group('ErrorMapper malformed bodies', () {
    // Indexing a non-map body with 'message' used to throw, turning a handled
    // server error into an unhandled crash.
    test('a list body does not throw', () {
      expect(() => ErrorMapper.fromDioException(_badResponse(500, [1, 2])),
          returnsNormally);
    });

    test('a string body does not throw', () {
      expect(() => ErrorMapper.fromDioException(_badResponse(502, 'Bad Gateway')),
          returnsNormally);
    });

    test('a null body does not throw', () {
      expect(() => ErrorMapper.fromDioException(_badResponse(500, null)),
          returnsNormally);
    });

    test('a non-string message falls back rather than crashing', () {
      final f = ErrorMapper.fromDioException(_badResponse(400, {'message': 42}));
      expect(f.message, 'Server error');
    });
  });

  group('ErrorMapper preserves the server message', () {
    // These branches replaced the server's explanation with a constant, so the
    // only account of what went wrong was discarded.
    test('403 keeps the reason', () {
      final f = ErrorMapper.fromDioException(_badResponse(
          403, {'message': 'Verify your email to use the feed'}));
      expect(f.message, 'Verify your email to use the feed');
    });

    test('404 keeps the reason', () {
      final f = ErrorMapper.fromDioException(
          _badResponse(404, {'message': 'Group not found'}));
      expect(f.message, 'Group not found');
    });

    test('429 keeps the reason', () {
      final f = ErrorMapper.fromDioException(_badResponse(
          429, {'message': 'Too many failed sign-in attempts. Try again later.'}));
      expect(f.message, 'Too many failed sign-in attempts. Try again later.');
      expect(f.statusCode, 429);
    });
  });
}
