import 'media_type.dart';

class MediaAsset {
  const MediaAsset({
    required this.id,
    required this.originalFilename,
    required this.mimeType,
    required this.sizeBytes,
    required this.processingState,
    required this.moderationState,
    required this.visibility,
    required this.createdAt,
    this.width,
    this.height,
    this.durationSeconds,
  });

  final String id;
  final String originalFilename;
  final String mimeType;
  final int sizeBytes;
  final int? width;
  final int? height;
  final double? durationSeconds;
  final MediaProcessingState processingState;
  final MediaModerationState moderationState;
  final MediaVisibility visibility;
  final DateTime createdAt;

  bool get isReady => processingState == MediaProcessingState.ready;
  bool get isRemoved =>
      moderationState == MediaModerationState.removed ||
      moderationState == MediaModerationState.rejected;

  factory MediaAsset.fromJson(Map<String, dynamic> json) {
    return MediaAsset(
      id: json['id'] as String,
      originalFilename: json['originalFilename'] as String,
      mimeType: json['mimeType'] as String,
      sizeBytes: json['sizeBytes'] as int,
      width: json['width'] as int?,
      height: json['height'] as int?,
      durationSeconds: (json['durationSeconds'] as num?)?.toDouble(),
      processingState: mediaProcessingStateFromJson(
        json['processingState'] as String,
      ),
      moderationState: mediaModerationStateFromJson(
        json['moderationState'] as String,
      ),
      visibility: mediaVisibilityFromJson(json['visibility'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
