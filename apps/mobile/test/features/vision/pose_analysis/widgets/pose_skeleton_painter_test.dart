import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/vision/pose_analysis/presentation/widgets/pose_skeleton_painter.dart';

void main() {
  group('scalePoint', () {
    test('maps a point at image origin to canvas origin', () {
      final point = scalePoint(
        x: 0,
        y: 0,
        imageSize: const Size(640, 480),
        canvasSize: const Size(320, 240),
      );
      expect(point, Offset.zero);
    });

    test('scales proportionally when canvas is smaller than the image', () {
      final point = scalePoint(
        x: 320,
        y: 240,
        imageSize: const Size(640, 480),
        canvasSize: const Size(320, 240),
      );
      expect(point, const Offset(160, 120));
    });

    test('scales proportionally when canvas is larger than the image', () {
      final point = scalePoint(
        x: 100,
        y: 50,
        imageSize: const Size(200, 100),
        canvasSize: const Size(400, 200),
      );
      expect(point, const Offset(200, 100));
    });

    test('returns zero for a degenerate zero-sized image rather than dividing by zero', () {
      final point = scalePoint(
        x: 10,
        y: 10,
        imageSize: Size.zero,
        canvasSize: const Size(320, 240),
      );
      expect(point, Offset.zero);
    });
  });
}
