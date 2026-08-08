/// Build Session 10 Part 3 deliberately starts with only the exercises
/// whose repetition can be reasonably distinguished from 2D landmarks
/// alone — a front-facing single-camera view can't reliably resolve
/// depth, so anything where the key motion is toward/away from the
/// camera (rather than up/down or open/close in the image plane) is
/// excluded for now. If any of these three proves unreliable in
/// practice, the honest response is to drop it from this list, not to
/// ship a fake result — see `ExercisePoseAnalyzer`'s doc comment.
enum SupportedExercise { bodyweightSquat, bicepsCurl, shoulderPress }

String supportedExerciseLabel(SupportedExercise exercise) {
  switch (exercise) {
    case SupportedExercise.bodyweightSquat:
      return 'Bodyweight squat';
    case SupportedExercise.bicepsCurl:
      return 'Biceps curl';
    case SupportedExercise.shoulderPress:
      return 'Shoulder press';
  }
}

/// URL-safe route-parameter id — distinct from the backend's
/// SCREAMING_SNAKE_CASE wire format (see `supportedExerciseToJson`).
String supportedExerciseRouteId(SupportedExercise exercise) {
  switch (exercise) {
    case SupportedExercise.bodyweightSquat:
      return 'bodyweight-squat';
    case SupportedExercise.bicepsCurl:
      return 'biceps-curl';
    case SupportedExercise.shoulderPress:
      return 'shoulder-press';
  }
}

SupportedExercise? supportedExerciseFromRouteId(String id) {
  switch (id) {
    case 'bodyweight-squat':
      return SupportedExercise.bodyweightSquat;
    case 'biceps-curl':
      return SupportedExercise.bicepsCurl;
    case 'shoulder-press':
      return SupportedExercise.shoulderPress;
    default:
      return null;
  }
}
