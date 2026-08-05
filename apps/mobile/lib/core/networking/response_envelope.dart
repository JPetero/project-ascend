/// Mirrors the backend's `{ data, meta, error }` response envelope.
class ResponseEnvelope<T> {
  const ResponseEnvelope({required this.data, required this.meta, this.error});

  final T? data;
  final Map<String, dynamic> meta;
  final ApiError? error;

  static ResponseEnvelope<T> fromJson<T>(
    Map<String, dynamic> json,
    T Function(dynamic) fromData,
  ) {
    return ResponseEnvelope<T>(
      data: json['data'] == null ? null : fromData(json['data']),
      meta: (json['meta'] as Map<String, dynamic>?) ?? const {},
      error: json['error'] == null
          ? null
          : ApiError.fromJson(json['error'] as Map<String, dynamic>),
    );
  }
}

class ApiError {
  const ApiError({required this.code, required this.message, this.details});

  final String code;
  final String message;
  final Map<String, dynamic>? details;

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      code: json['code'] as String? ?? 'UNKNOWN',
      message: json['message'] as String? ?? 'Something went wrong.',
      details: json['details'] as Map<String, dynamic>?,
    );
  }
}
