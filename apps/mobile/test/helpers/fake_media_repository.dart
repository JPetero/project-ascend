import 'package:dio/dio.dart';
import 'package:mobile/core/media/data/media_repository.dart';
import 'package:mobile/core/media/domain/media_asset.dart';
import 'package:mobile/core/media/domain/media_type.dart';

MediaAsset sampleMediaAsset({
  String id = 'media-1',
  String originalFilename = 'photo.jpg',
  String mimeType = 'image/jpeg',
  int sizeBytes = 1000,
  MediaProcessingState processingState = MediaProcessingState.ready,
  MediaModerationState moderationState = MediaModerationState.approved,
  MediaVisibility visibility = MediaVisibility.private,
}) {
  return MediaAsset(
    id: id,
    originalFilename: originalFilename,
    mimeType: mimeType,
    sizeBytes: sizeBytes,
    processingState: processingState,
    moderationState: moderationState,
    visibility: visibility,
    createdAt: DateTime.utc(2026, 8, 7),
  );
}

/// In-memory stand-in for [MediaRepository].
class FakeMediaRepository implements MediaRepository {
  FakeMediaRepository({List<MediaAsset>? assets}) : assets = assets ?? [];

  final List<MediaAsset> assets;
  bool failUpload = false;
  int uploadCount = 0;

  @override
  Future<MediaUploadHandle> initiateUpload({
    required AscendMediaType mediaType,
    required String originalFilename,
    required String mimeType,
    required int sizeBytes,
    int? width,
    int? height,
    double? durationSeconds,
  }) async {
    final id = 'media-${assets.length}';
    assets.insert(
      0,
      MediaAsset(
        id: id,
        originalFilename: originalFilename,
        mimeType: mimeType,
        sizeBytes: sizeBytes,
        processingState: MediaProcessingState.pending,
        moderationState: MediaModerationState.pending,
        visibility: MediaVisibility.private,
        createdAt: DateTime.now(),
      ),
    );
    return MediaUploadHandle(
      mediaAssetId: id,
      uploadUrl: '/media/uploads/$id/local-bytes',
      uploadMethod: 'POST',
    );
  }

  @override
  Future<void> uploadLocalBytes({
    required String mediaAssetId,
    required List<int> bytes,
    void Function(int sent, int total)? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    uploadCount += 1;
    onSendProgress?.call(bytes.length, bytes.length);
    if (failUpload) {
      throw Exception('upload failed');
    }
    final index = assets.indexWhere((a) => a.id == mediaAssetId);
    if (index != -1) {
      final existing = assets[index];
      assets[index] = MediaAsset(
        id: existing.id,
        originalFilename: existing.originalFilename,
        mimeType: existing.mimeType,
        sizeBytes: existing.sizeBytes,
        processingState: MediaProcessingState.ready,
        moderationState: MediaModerationState.approved,
        visibility: existing.visibility,
        createdAt: existing.createdAt,
      );
    }
  }

  @override
  Future<MediaAsset> completeUpload(String mediaAssetId) async {
    return assets.firstWhere((a) => a.id == mediaAssetId);
  }

  @override
  Future<MediaAsset> getById(String mediaAssetId) async {
    return assets.firstWhere(
      (a) => a.id == mediaAssetId,
      orElse: () => throw Exception('not found'),
    );
  }

  @override
  Future<List<MediaAsset>> listMine() async => List.unmodifiable(assets);

  @override
  Future<void> setVisibility(
    String mediaAssetId,
    MediaVisibility visibility,
  ) async {
    final index = assets.indexWhere((a) => a.id == mediaAssetId);
    if (index == -1) return;
    final existing = assets[index];
    assets[index] = MediaAsset(
      id: existing.id,
      originalFilename: existing.originalFilename,
      mimeType: existing.mimeType,
      sizeBytes: existing.sizeBytes,
      processingState: existing.processingState,
      moderationState: existing.moderationState,
      visibility: visibility,
      createdAt: existing.createdAt,
    );
  }

  @override
  Future<void> deleteAsset(String mediaAssetId) async {
    assets.removeWhere((a) => a.id == mediaAssetId);
  }

  @override
  Future<void> reportAsset(String mediaAssetId, String reason) async {}
}
