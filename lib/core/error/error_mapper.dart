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
      DioExceptionType.badResponse => _fromStatusCode(
        e.response?.statusCode,
        e.response?.data?['message'] ?? 'Server error',
      ),
      _ => ServerFailure(e.message ?? 'Unexpected error'),
    };
  }

  static Failure _fromStatusCode(int? code, String message) {
    return switch (code) {
      401 => AuthFailure(message, statusCode: code),
      403 => AuthFailure('Access denied', statusCode: code),
      404 => ServerFailure('Not found', statusCode: code),
      409 => ServerFailure(message, statusCode: code),
      422 => ValidationFailure(message),
      429 => ServerFailure('Too many requests', statusCode: code),
      _ => ServerFailure(message, statusCode: code),
    };
  }
}
