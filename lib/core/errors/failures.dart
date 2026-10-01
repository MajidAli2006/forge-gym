import 'package:equatable/equatable.dart';

/// Domain-level failures.
///
/// Data-layer exceptions (e.g. [DioException]) are mapped to these before
/// they leave the repository — UI code never sees raw technical errors,
/// only user-friendly messages.
sealed class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message =
        'No internet connection. Check your connection and try again.',
  ]);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([
    super.message = 'Your session has expired. Please sign in again.',
  ]);
}

class ServerFailure extends Failure {
  const ServerFailure([
    super.message = 'Something went wrong on our side. Please try again later.',
  ]);
}

class CacheFailure extends Failure {
  const CacheFailure([
    super.message = 'Saved data is unavailable right now. Please try again.',
  ]);
}

/// Input failed validation (email format, password length, required fields…).
/// Thrown by use cases; UI shows [message] near the offending field.
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class UnknownFailure extends Failure {
  const UnknownFailure([
    super.message = 'Something unexpected happened. Please try again.',
  ]);
}
