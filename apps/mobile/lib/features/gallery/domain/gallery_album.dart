/// Mirrors services/api/prisma/schema.prisma's GalleryCategory — Build
/// Session 9 Part 2. SHARED and PRIVATE describe the album's own state
/// as much as a topic; an album's category and its visibility
/// ([GalleryVisibility]) are tracked separately.
enum GalleryCategory {
  progress,
  workouts,
  meals,
  cardio,
  achievements,
  vision,
  shared,
  private_,
}

String galleryCategoryToJson(GalleryCategory category) => switch (category) {
  GalleryCategory.progress => 'PROGRESS',
  GalleryCategory.workouts => 'WORKOUTS',
  GalleryCategory.meals => 'MEALS',
  GalleryCategory.cardio => 'CARDIO',
  GalleryCategory.achievements => 'ACHIEVEMENTS',
  GalleryCategory.vision => 'VISION',
  GalleryCategory.shared => 'SHARED',
  GalleryCategory.private_ => 'PRIVATE',
};

GalleryCategory galleryCategoryFromJson(String value) => switch (value) {
  'PROGRESS' => GalleryCategory.progress,
  'WORKOUTS' => GalleryCategory.workouts,
  'MEALS' => GalleryCategory.meals,
  'CARDIO' => GalleryCategory.cardio,
  'ACHIEVEMENTS' => GalleryCategory.achievements,
  'VISION' => GalleryCategory.vision,
  'SHARED' => GalleryCategory.shared,
  _ => GalleryCategory.private_,
};

String galleryCategoryLabel(GalleryCategory category) => switch (category) {
  GalleryCategory.progress => 'Progress',
  GalleryCategory.workouts => 'Workouts',
  GalleryCategory.meals => 'Meals',
  GalleryCategory.cardio => 'Cardio',
  GalleryCategory.achievements => 'Achievements',
  GalleryCategory.vision => 'Vision',
  GalleryCategory.shared => 'Shared',
  GalleryCategory.private_ => 'Private',
};

/// Private by default — see GalleryAlbum's schema comment.
enum GalleryVisibility { private_, shared }

String galleryVisibilityToJson(GalleryVisibility visibility) =>
    visibility == GalleryVisibility.shared ? 'SHARED' : 'PRIVATE';

GalleryVisibility galleryVisibilityFromJson(String value) =>
    value == 'SHARED' ? GalleryVisibility.shared : GalleryVisibility.private_;

String galleryVisibilityLabel(GalleryVisibility visibility) =>
    switch (visibility) {
      GalleryVisibility.private_ => 'Private',
      GalleryVisibility.shared => 'Shared to Community',
    };

class GalleryAlbum {
  const GalleryAlbum({
    required this.id,
    required this.name,
    required this.category,
    required this.visibility,
    required this.mediaCount,
    required this.createdAt,
  });

  final String id;
  final String name;
  final GalleryCategory category;
  final GalleryVisibility visibility;
  final int mediaCount;
  final DateTime createdAt;

  factory GalleryAlbum.fromJson(Map<String, dynamic> json) {
    return GalleryAlbum(
      id: json['id'] as String,
      name: json['name'] as String,
      category: galleryCategoryFromJson(json['category'] as String),
      visibility: galleryVisibilityFromJson(json['visibility'] as String),
      mediaCount: json['mediaCount'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
