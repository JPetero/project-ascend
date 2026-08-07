/// Mirrors `services/api/prisma/schema.prisma`'s `MediaType` enum —
/// Build Session 8 Part 2's Media Platform.
enum AscendMediaType {
  profileImage,
  coverImage,
  communityImage,
  communityReel,
  chatImage,
  mealPhoto,
  progressPhoto,
  visionCapture,
  workoutShareMedia,
}

String mediaTypeToJson(AscendMediaType type) {
  switch (type) {
    case AscendMediaType.profileImage:
      return 'PROFILE_IMAGE';
    case AscendMediaType.coverImage:
      return 'COVER_IMAGE';
    case AscendMediaType.communityImage:
      return 'COMMUNITY_IMAGE';
    case AscendMediaType.communityReel:
      return 'COMMUNITY_REEL';
    case AscendMediaType.chatImage:
      return 'CHAT_IMAGE';
    case AscendMediaType.mealPhoto:
      return 'MEAL_PHOTO';
    case AscendMediaType.progressPhoto:
      return 'PROGRESS_PHOTO';
    case AscendMediaType.visionCapture:
      return 'VISION_CAPTURE';
    case AscendMediaType.workoutShareMedia:
      return 'WORKOUT_SHARE_MEDIA';
  }
}

enum MediaProcessingState { pending, processing, ready, failed }

MediaProcessingState mediaProcessingStateFromJson(String value) {
  switch (value) {
    case 'PROCESSING':
      return MediaProcessingState.processing;
    case 'READY':
      return MediaProcessingState.ready;
    case 'FAILED':
      return MediaProcessingState.failed;
    default:
      return MediaProcessingState.pending;
  }
}

enum MediaModerationState { pending, approved, flagged, rejected, removed }

MediaModerationState mediaModerationStateFromJson(String value) {
  switch (value) {
    case 'APPROVED':
      return MediaModerationState.approved;
    case 'FLAGGED':
      return MediaModerationState.flagged;
    case 'REJECTED':
      return MediaModerationState.rejected;
    case 'REMOVED':
      return MediaModerationState.removed;
    default:
      return MediaModerationState.pending;
  }
}

enum MediaVisibility { private, unlisted, public }

String mediaVisibilityToJson(MediaVisibility visibility) {
  switch (visibility) {
    case MediaVisibility.private:
      return 'PRIVATE';
    case MediaVisibility.unlisted:
      return 'UNLISTED';
    case MediaVisibility.public:
      return 'PUBLIC';
  }
}

MediaVisibility mediaVisibilityFromJson(String value) {
  switch (value) {
    case 'UNLISTED':
      return MediaVisibility.unlisted;
    case 'PUBLIC':
      return MediaVisibility.public;
    default:
      return MediaVisibility.private;
  }
}
