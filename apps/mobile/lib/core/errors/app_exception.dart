/// A normalized error surfaced to the UI layer, translated from network,
/// storage, or validation failures so widgets never handle raw exceptions.
class AppException implements Exception {
  const AppException({required this.message, this.code});

  final String message;
  final String? code;

  factory AppException.network() => const AppException(
    message: 'Unable to reach Ascend. Check your connection and try again.',
    code: 'NETWORK_ERROR',
  );

  factory AppException.unauthorized() => const AppException(
    message: 'Your session has expired. Please sign in again.',
    code: 'UNAUTHORIZED',
  );

  factory AppException.unknown() => const AppException(
    message: 'Something went wrong. Please try again.',
    code: 'UNKNOWN',
  );

  @override
  String toString() => message;
}
