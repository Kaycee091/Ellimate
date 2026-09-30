class AppException implements Exception {
  final String message;
  final String? code;
  final Object? originalError;

  const AppException({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'AppException: $message (code: $code)';
}

class NetworkException extends AppException {
  const NetworkException({
    super.message = 'No internet connection. Please check your network.',
    super.code = 'network_error',
    super.originalError,
  });
}

class AppAuthException extends AppException {
  const AppAuthException({
    required super.message,
    super.code = 'auth_error',
    super.originalError,
  });
}

class DatabaseException extends AppException {
  const DatabaseException({
    required super.message,
    super.code = 'database_error',
    super.originalError,
  });
}

class ValidationException extends AppException {
  const ValidationException({
    required super.message,
    super.code = 'validation_error',
  });
}

class ConflictException extends AppException {
  const ConflictException({
    required super.message,
    super.code = 'conflict',
    super.originalError,
  });
}

class NotFoundException extends AppException {
  const NotFoundException({
    required super.message,
    super.code = 'not_found',
  });
}

String friendlyError(Object error) {
  if (error is AppException) return error.message;
  final msg = error.toString().toLowerCase();
  if (msg.contains('network') || msg.contains('socket') || msg.contains('connection')) {
    return 'Unable to connect. Please check your internet connection.';
  }
  if (msg.contains('duplicate') || msg.contains('unique')) {
    return 'This record already exists.';
  }
  if (msg.contains('permission') || msg.contains('unauthorized')) {
    return 'You don\'t have permission to do this.';
  }
  return 'Something went wrong. Please try again.';
}
