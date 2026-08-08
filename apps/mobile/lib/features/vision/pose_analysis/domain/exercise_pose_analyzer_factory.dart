import 'biceps_curl_pose_analyzer.dart';
import 'exercise_pose_analyzer.dart';
import 'shoulder_press_pose_analyzer.dart';
import 'squat_pose_analyzer.dart';
import 'supported_exercise.dart';

/// One place that knows which concrete analyzer backs each
/// [SupportedExercise] — the live session controller and any future
/// caller ask this factory instead of switching on the exercise
/// themselves.
ExercisePoseAnalyzer createExercisePoseAnalyzer(SupportedExercise exercise) {
  switch (exercise) {
    case SupportedExercise.bodyweightSquat:
      return SquatPoseAnalyzer();
    case SupportedExercise.bicepsCurl:
      return BicepsCurlPoseAnalyzer();
    case SupportedExercise.shoulderPress:
      return ShoulderPressPoseAnalyzer();
  }
}
