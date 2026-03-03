/// Core exception classes for the application.
/// All exceptions must inherit from [AppException] for proper error handling.
library;

/// Base exception class for all custom exceptions
abstract class AppException implements Exception {
  AppException({required this.message, this.stackTrace});

  /// Exception message
  final String message;

  /// Stack trace for debugging
  final StackTrace? stackTrace;

  @override
  String toString() => message;
}

/// Authentication related exceptions
class AuthException extends AppException {
  AuthException({required super.message, super.stackTrace});
}

/// Network related exceptions
class NetworkException extends AppException {
  NetworkException({required super.message, super.stackTrace});
}

/// Server related exceptions
class ServerException extends AppException {
  ServerException({
    required String message,
    this.statusCode,
    StackTrace? stackTrace,
  }) : super(message: message, stackTrace: stackTrace);
  final int? statusCode;
}

/// Cache related exceptions
class CacheException extends AppException {
  CacheException({required super.message, super.stackTrace});
}

/// Data parsing exceptions
class DataException extends AppException {
  DataException({required super.message, super.stackTrace});
}

/// Verification related exceptions
class VerificationException extends AppException {
  VerificationException({required super.message, super.stackTrace});
}

/// Business logic exceptions
class BusinessException extends AppException {
  BusinessException({required super.message, super.stackTrace});
}
