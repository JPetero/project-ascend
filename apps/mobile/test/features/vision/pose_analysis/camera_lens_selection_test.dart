import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/vision/pose_analysis/domain/camera_lens_selection.dart';

const _back = CameraDescription(
  name: 'back-camera',
  lensDirection: CameraLensDirection.back,
  sensorOrientation: 90,
);
const _front = CameraDescription(
  name: 'front-camera',
  lensDirection: CameraLensDirection.front,
  sensorOrientation: 270,
);

void main() {
  group('selectCameraForLensDirection', () {
    test('returns null when the device reports no cameras at all', () {
      expect(
        selectCameraForLensDirection([], CameraLensDirection.back),
        isNull,
      );
    });

    test('picks the camera matching the requested lens direction', () {
      final result = selectCameraForLensDirection([
        _back,
        _front,
      ], CameraLensDirection.front);

      expect(result, _front);
    });

    test(
      'falls back to the first camera when none matches the requested direction',
      () {
        final result = selectCameraForLensDirection([
          _back,
        ], CameraLensDirection.front);

        expect(result, _back);
      },
    );
  });

  group('hasBothLensDirections', () {
    test('true when both a front and back camera are present', () {
      expect(hasBothLensDirections([_back, _front]), isTrue);
    });

    test('false when only one lens direction is available', () {
      expect(hasBothLensDirections([_back]), isFalse);
    });

    test('false for an empty camera list', () {
      expect(hasBothLensDirections([]), isFalse);
    });
  });

  group('oppositeLensDirection', () {
    test('front becomes back', () {
      expect(
        oppositeLensDirection(CameraLensDirection.front),
        CameraLensDirection.back,
      );
    });

    test('back becomes front', () {
      expect(
        oppositeLensDirection(CameraLensDirection.back),
        CameraLensDirection.front,
      );
    });

    test(
      'external is treated as needing a front camera next, same as back',
      () {
        expect(
          oppositeLensDirection(CameraLensDirection.external),
          CameraLensDirection.front,
        );
      },
    );
  });
}
