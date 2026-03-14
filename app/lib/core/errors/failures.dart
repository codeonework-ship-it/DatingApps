/// Failure classes for proper error handling in the domain layer.
/// These are returned instead of throwing exceptions in use cases.
library;

abstract class Failure {
  Failure({required this.message});

  /// Error message
  final String message;
}

/// Network failure
class NetworkFailure extends Failure {
  NetworkFailure({required super.message});
}

/// Server failure with optional status code
class ServerFailure extends Failure {
  ServerFailure({required super.message, this.statusCode});
  final int? statusCode;
}

/// Authentication failure
class AuthFailure extends Failure {
  AuthFailure({required super.message});
}

/// Verification failure
class VerificationFailure extends Failure {
  VerificationFailure({required super.message});
}

/// Cache failure
class CacheFailure extends Failure {
  CacheFailure({required super.message});
}

/// Data parsing failure
class DataFailure extends Failure {
  DataFailure({required super.message});
}

/// Business logic failure
class BusinessFailure extends Failure {
  BusinessFailure({required super.message});
}

/// Unknown failure
class UnknownFailure extends Failure {
  UnknownFailure({required super.message});
}
