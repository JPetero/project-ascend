import 'dart:convert';

import 'package:dio/dio.dart';

import '../../networking/api_client.dart';
import '../domain/media_asset.dart';
import '../domain/media_type.dart';

class MediaUploadHandle {
  const MediaUploadHandle({
    required this.mediaAssetId,
    required this.uploadUrl,
    required this.uploadMethod,
  });

  final String mediaAssetId;
  final String uploadUrl;
  final String uploadMethod;
}

/// Thin client for `services/api/src/modules/media` — Build Session 8
/// Part 2/3's shared Media Platform. Every feature that attaches a
/// photo/video goes through this repository rather than each wiring
/// its own upload call.
class MediaRepository {
  MediaRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<MediaUploadHandle> initiateUpload({
    required AscendMediaType mediaType,
    required String originalFilename,
    required String mimeType,
    required int sizeBytes,
    int? width,
    int? height,
    double? durationSeconds,
  }) async {
    final envelope = await _apiClient.post(
      '/media/uploads',
      (data) => data as Map<String, dynamic>,
      data: {
        'mediaType': mediaTypeToJson(mediaType),
        'originalFilename': originalFilename,
        'mimeType': mimeType,
        'sizeBytes': sizeBytes,
        'width': ?width,
        'height': ?height,
        'durationSeconds': ?durationSeconds,
      },
    );
    final body = envelope.data!;
    final mediaAsset = body['mediaAsset'] as Map<String, dynamic>;
    final uploadTarget = body['uploadTarget'] as Map<String, dynamic>;
    return MediaUploadHandle(
      mediaAssetId: mediaAsset['id'] as String,
      uploadUrl: uploadTarget['url'] as String,
      uploadMethod: uploadTarget['method'] as String,
    );
  }

  /// Local-dev-only completion path — see `LocalDevelopmentStorageProvider`.
  /// A production build talking to the S3-compatible provider would PUT
  /// the raw bytes to `uploadUrl` instead, then call [completeUpload].
  Future<void> uploadLocalBytes({
    required String mediaAssetId,
    required List<int> bytes,
    void Function(int sent, int total)? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    await _apiClient.post(
      '/media/uploads/$mediaAssetId/local-bytes',
      (_) => null,
      data: {'base64': base64Encode(bytes)},
      onSendProgress: onSendProgress,
      cancelToken: cancelToken,
    );
  }

  Future<MediaAsset> completeUpload(String mediaAssetId) async {
    final envelope = await _apiClient.post(
      '/media/$mediaAssetId/complete',
      (data) => data as Map<String, dynamic>,
    );
    return MediaAsset.fromJson(envelope.data!);
  }

  Future<MediaAsset> getById(String mediaAssetId) async {
    final envelope = await _apiClient.get(
      '/media/$mediaAssetId',
      (data) => data as Map<String, dynamic>,
    );
    return MediaAsset.fromJson(envelope.data!);
  }

  Future<List<MediaAsset>> listMine() async {
    final envelope = await _apiClient.get(
      '/media/mine',
      (data) => data as List<dynamic>,
    );
    return envelope.data!
        .map((m) => MediaAsset.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  Future<void> setVisibility(
    String mediaAssetId,
    MediaVisibility visibility,
  ) async {
    await _apiClient.patch(
      '/media/$mediaAssetId/visibility',
      (_) => null,
      data: {'visibility': mediaVisibilityToJson(visibility)},
    );
  }

  Future<void> deleteAsset(String mediaAssetId) async {
    await _apiClient.delete('/media/$mediaAssetId', (_) => null);
  }

  Future<void> reportAsset(String mediaAssetId, String reason) async {
    await _apiClient.post(
      '/media/$mediaAssetId/report',
      (_) => null,
      data: {'reason': reason},
    );
  }
}
