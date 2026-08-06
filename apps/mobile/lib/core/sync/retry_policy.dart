/// Pure backoff math for the sync engine — kept dependency-free so it's
/// trivially unit-testable without a database or clock mock.
class RetryPolicy {
  const RetryPolicy({
    this.baseDelay = const Duration(seconds: 5),
    this.maxDelay = const Duration(minutes: 10),
    this.maxAttempts = 6,
  });

  final Duration baseDelay;
  final Duration maxDelay;

  /// After this many failed attempts, the engine stops retrying
  /// automatically and leaves the entry `failed` for a manual retry —
  /// never a tight infinite loop.
  final int maxAttempts;

  bool hasAttemptsRemaining(int retryCount) => retryCount < maxAttempts;

  /// Exponential backoff (`baseDelay * 2^retryCount`), capped at
  /// [maxDelay]. `retryCount` is the number of *prior* failed attempts, so
  /// the first retry (retryCount == 0) waits exactly [baseDelay].
  Duration delayFor(int retryCount) {
    final scaled = baseDelay * (1 << retryCount.clamp(0, 20));
    return scaled > maxDelay ? maxDelay : scaled;
  }
}

/// Whether an error is worth retrying automatically at all. A validation
/// failure, a forbidden action, or a 404 will not start succeeding just
/// because time passed — those go straight to `failed` and wait for
/// explicit user action (edit and resubmit, or discard), never silently
/// vanish and never spin the retry budget pointlessly.
bool isRetryableErrorCode(String? code) {
  switch (code) {
    case 'VALIDATION_ERROR':
    case 'FORBIDDEN':
    case 'NOT_FOUND':
    case 'UNAUTHORIZED':
      return false;
    default:
      // NETWORK_ERROR, CONFLICT (another in-flight attempt with the same
      // key), RATE_LIMITED, INTERNAL_SERVER_ERROR, UNKNOWN, and anything
      // unrecognized are all treated as transient.
      return true;
  }
}
