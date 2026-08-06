import 'dart:math';

final _random = Random();

/// A locally-unique-enough key for one mutation attempt: timestamp plus a
/// random component, formatted so it's also safe to use as a Drift
/// primary-key string and an outbox entry id. Not a UUID — this app has no
/// other use for a UUID package, and this is exactly as collision-resistant
/// as one needs to be for "unique per device per mutation."
String generateIdempotencyKey(String scope) =>
    '$scope-${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(1 << 32)}';
