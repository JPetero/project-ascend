import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/sync/retry_policy.dart';

void main() {
  group('RetryPolicy', () {
    const policy = RetryPolicy(
      baseDelay: Duration(seconds: 5),
      maxDelay: Duration(minutes: 10),
      maxAttempts: 6,
    );

    test('delayFor doubles with each retry count, starting at baseDelay', () {
      expect(policy.delayFor(0), const Duration(seconds: 5));
      expect(policy.delayFor(1), const Duration(seconds: 10));
      expect(policy.delayFor(2), const Duration(seconds: 20));
      expect(policy.delayFor(3), const Duration(seconds: 40));
    });

    test('delayFor is capped at maxDelay instead of growing unbounded', () {
      expect(policy.delayFor(10), const Duration(minutes: 10));
      expect(policy.delayFor(30), const Duration(minutes: 10));
    });

    test('hasAttemptsRemaining is true below maxAttempts and false at or above it', () {
      expect(policy.hasAttemptsRemaining(0), isTrue);
      expect(policy.hasAttemptsRemaining(5), isTrue);
      expect(policy.hasAttemptsRemaining(6), isFalse);
      expect(policy.hasAttemptsRemaining(100), isFalse);
    });
  });

  group('isRetryableErrorCode', () {
    test('treats permanent client errors as not retryable', () {
      expect(isRetryableErrorCode('VALIDATION_ERROR'), isFalse);
      expect(isRetryableErrorCode('FORBIDDEN'), isFalse);
      expect(isRetryableErrorCode('NOT_FOUND'), isFalse);
      expect(isRetryableErrorCode('UNAUTHORIZED'), isFalse);
    });

    test('treats transient/unknown errors as retryable', () {
      expect(isRetryableErrorCode('NETWORK_ERROR'), isTrue);
      expect(isRetryableErrorCode('CONFLICT'), isTrue);
      expect(isRetryableErrorCode('RATE_LIMITED'), isTrue);
      expect(isRetryableErrorCode('INTERNAL_SERVER_ERROR'), isTrue);
      expect(isRetryableErrorCode('UNKNOWN'), isTrue);
      expect(isRetryableErrorCode(null), isTrue);
      expect(isRetryableErrorCode('SOME_FUTURE_CODE'), isTrue);
    });
  });
}
