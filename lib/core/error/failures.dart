import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable {
  final String message;
  final int? statusCode;

  /// Server-reported problems keyed by the field that caused them.
  ///
  /// Populated from a 422's `errors` map or a conflict naming a single
  /// `field`, so a form can mark the offending input instead of dropping
  /// everything into one banner.
  final Map<String, String> fieldErrors;

  const Failure(
    this.message, {
    this.statusCode,
    this.fieldErrors = const {},
  });

  @override
  List<Object?> get props => [message, statusCode, fieldErrors];
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.statusCode, super.fieldErrors});
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache error']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.statusCode, super.fieldErrors});
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.statusCode, super.fieldErrors});
}
