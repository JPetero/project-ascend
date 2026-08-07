import '../config/app_config.dart';

/// Resolves a possibly-relative media URL (the local-dev storage
/// provider serves `/media/objects/...` API-relative paths) into an
/// absolute URL the Flutter client can actually fetch. An
/// already-absolute URL (the S3-compatible provider, or a
/// legacy externally-hosted mediaUrl) passes through unchanged.
String resolveMediaUrl(String url) {
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  return '${AppConfig.apiBaseUrl}$url';
}
