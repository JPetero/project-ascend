/// Standardized angles for progress photos — mirrors
/// services/api/prisma/schema.prisma's GalleryPoseTag. Optional and
/// only meaningful on a PROGRESS-category album's media; nothing
/// enforces the pairing.
enum GalleryPoseTag { front, side, back }

String galleryPoseTagToJson(GalleryPoseTag tag) => switch (tag) {
  GalleryPoseTag.front => 'FRONT',
  GalleryPoseTag.side => 'SIDE',
  GalleryPoseTag.back => 'BACK',
};

GalleryPoseTag? galleryPoseTagFromJson(String? value) => switch (value) {
  'FRONT' => GalleryPoseTag.front,
  'SIDE' => GalleryPoseTag.side,
  'BACK' => GalleryPoseTag.back,
  _ => null,
};

String galleryPoseTagLabel(GalleryPoseTag tag) => switch (tag) {
  GalleryPoseTag.front => 'Front',
  GalleryPoseTag.side => 'Side',
  GalleryPoseTag.back => 'Back',
};

class GalleryMedia {
  const GalleryMedia({
    required this.id,
    required this.albumId,
    required this.mediaAssetId,
    required this.url,
    this.note,
    this.poseTag,
    this.weightNote,
    this.capturedAt,
    required this.createdAt,
  });

  final String id;
  final String albumId;
  final String mediaAssetId;
  final String url;
  final String? note;
  final GalleryPoseTag? poseTag;
  // A user-typed note, e.g. "72kg" — never a value Ascend measures,
  // infers, or calculates.
  final String? weightNote;
  final DateTime? capturedAt;
  final DateTime createdAt;

  factory GalleryMedia.fromJson(Map<String, dynamic> json) {
    return GalleryMedia(
      id: json['id'] as String,
      albumId: json['albumId'] as String,
      mediaAssetId: json['mediaAssetId'] as String,
      url: json['url'] as String,
      note: json['note'] as String?,
      poseTag: galleryPoseTagFromJson(json['poseTag'] as String?),
      weightNote: json['weightNote'] as String?,
      capturedAt: json['capturedAt'] != null
          ? DateTime.parse(json['capturedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class GalleryAlbumDetail {
  const GalleryAlbumDetail({
    required this.id,
    required this.name,
    required this.category,
    required this.media,
  });

  final String id;
  final String name;
  final String category;
  final List<GalleryMedia> media;

  factory GalleryAlbumDetail.fromJson(Map<String, dynamic> json) {
    return GalleryAlbumDetail(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      media: (json['media'] as List<dynamic>)
          .map((m) => GalleryMedia.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}
