import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../errors/app_exception.dart';
import '../storage/secure_token_storage.dart';
import 'response_envelope.dart';

/// Paths that must never receive an Authorization header or trigger a
/// refresh-and-retry (refreshing itself would recurse otherwise).
const _publicPaths = [
  '/auth/register',
  '/auth/login',
  '/auth/refresh',
  '/health',
];

/// Wraps Dio with Project Ascend's base URL, automatic access-token
/// attachment, and automatic refresh-and-retry on a 401.
class ApiClient {
  ApiClient({required SecureTokenStorage tokenStorage, this.onSessionExpired})
    : _tokenStorage = tokenStorage,
      _dio = Dio(
        BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          connectTimeout: const Duration(seconds: 15),
        ),
      ) {
    _refreshDio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (!_publicPaths.any((path) => options.path.startsWith(path))) {
            final accessToken = await _tokenStorage.readAccessToken();
            if (accessToken != null) {
              options.headers['Authorization'] = 'Bearer $accessToken';
            }
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final isUnauthorized = error.response?.statusCode == 401;
          final isPublicPath = _publicPaths.any(
            (path) => error.requestOptions.path.startsWith(path),
          );

          if (isUnauthorized && !isPublicPath) {
            final retried = await _retryWithRefreshedToken(
              error.requestOptions,
            );
            if (retried != null) {
              return handler.resolve(retried);
            }
            await _tokenStorage.clear();
            onSessionExpired?.call();
          }

          handler.next(error);
        },
      ),
    );
  }

  final SecureTokenStorage _tokenStorage;
  final Dio _dio;
  late final Dio _refreshDio;
  final Future<void> Function()? onSessionExpired;

  Future<Response<dynamic>?> _retryWithRefreshedToken(
    RequestOptions failedRequest,
  ) async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null) return null;

    try {
      final response = await _refreshDio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final envelope = ResponseEnvelope.fromJson(
        response.data as Map<String, dynamic>,
        (data) => data as Map<String, dynamic>,
      );
      final tokens = envelope.data;
      if (tokens == null) return null;

      await _tokenStorage.saveTokens(
        accessToken: tokens['accessToken'] as String,
        refreshToken: tokens['refreshToken'] as String,
      );

      failedRequest.headers['Authorization'] =
          'Bearer ${tokens['accessToken']}';
      return _dio.fetch(failedRequest);
    } on DioException {
      return null;
    }
  }

  Future<ResponseEnvelope<T>> get<T>(
    String path,
    T Function(dynamic) fromData, {
    Map<String, dynamic>? query,
  }) {
    return _request(() => _dio.get(path, queryParameters: query), fromData);
  }

  Future<ResponseEnvelope<T>> post<T>(
    String path,
    T Function(dynamic) fromData, {
    Object? data,
  }) {
    return _request(() => _dio.post(path, data: data), fromData);
  }

  Future<ResponseEnvelope<T>> patch<T>(
    String path,
    T Function(dynamic) fromData, {
    Object? data,
  }) {
    return _request(() => _dio.patch(path, data: data), fromData);
  }

  Future<ResponseEnvelope<T>> delete<T>(
    String path,
    T Function(dynamic) fromData,
  ) {
    return _request(() => _dio.delete(path), fromData);
  }

  Future<ResponseEnvelope<T>> _request<T>(
    Future<Response<dynamic>> Function() call,
    T Function(dynamic) fromData,
  ) async {
    try {
      final response = await call();
      return ResponseEnvelope.fromJson(
        response.data as Map<String, dynamic>,
        fromData,
      );
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  AppException _mapError(DioException error) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return AppException.network();
    }

    if (error.response?.statusCode == 401) {
      return AppException.unauthorized();
    }

    final body = error.response?.data;
    if (body is Map<String, dynamic> && body['error'] is Map<String, dynamic>) {
      final errorBody = body['error'] as Map<String, dynamic>;
      return AppException(
        message: errorBody['message'] as String? ?? 'Something went wrong.',
        code: errorBody['code'] as String?,
      );
    }

    return AppException.unknown();
  }
}
