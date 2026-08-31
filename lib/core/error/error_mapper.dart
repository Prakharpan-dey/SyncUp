import 'package:dio/dio.dart';
import 'failures.dart';

class ErrorMapper {
  static Failure fromDioException(DioException e) {
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => const NetworkFailure(
        'Connection timed out',
      ),
      DioExceptionType.connectionError => const NetworkFailure(),
      DioExceptionType.badResponse => _fromResponse(e.response),
      _ => ServerFailure(e.message ?? 'Unexpected error'),
    };
  }

  static Failure _fromResponse(Response<dynamic>? response) {
    final body = response?.data;
    // Only an object body carries the API's error envelope. Indexing a List or
    // a String with 'message' throws, turning a handled server error into an
    // unhandled client crash.
    final map = body is Map<String, dynamic> ? body : const <String, dynamic>{};
    final message = map['message'] is String
        ? map['message'] as String
        : 'Server error';

    return _fromStatusCode(
      response?.statusCode,
      message,
      _fieldErrors(map, message),
    );
  }

  /// Pulls per-field messages out of either error shape the API produces.
  ///
  /// A 422 carries `errors` as field -> list of problems; a conflict names the
  /// single offending `field` instead.
  static Map<String, String> _fieldErrors(
    Map<String, dynamic> map,
    String message,
  ) {
    final field = map['field'];
    if (field is String && field.isNotEmpty) return {field: message};

    final errors = map['errors'];
    if (errors is! Map) return const {};

    final out = <String, String>{};
    errors.forEach((key, value) {
      if (key is! String) return;
      final text = value is List
          ? value.whereType<String>().join(', ')
          : value is String
              ? value
              : null;
      if (text != null && text.isNotEmpty) out[key] = text;
    });
    return out;
  }

  static Failure _fromStatusCode(
    int? code,
    String message,
    Map<String, String> fieldErrors,
  ) {
    // The server's message is kept on every branch. Replacing it with a
    // constant ("Access denied", "Not found") discarded the only explanation
    // the user was going to get.
    return switch (code) {
      401 => AuthFailure(message, statusCode: code, fieldErrors: fieldErrors),
      403 => AuthFailure(message, statusCode: code, fieldErrors: fieldErrors),
      404 => ServerFailure(message, statusCode: code),
      409 => ServerFailure(message, statusCode: code, fieldErrors: fieldErrors),
      422 => ValidationFailure(message,
          statusCode: code, fieldErrors: fieldErrors),
      429 => ServerFailure(message, statusCode: code),
      _ => ServerFailure(message, statusCode: code),
    };
  }
}
