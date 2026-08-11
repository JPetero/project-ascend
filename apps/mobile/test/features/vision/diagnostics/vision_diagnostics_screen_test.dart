import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/diagnostics/data/device_diagnostics_service.dart';
import 'package:mobile/core/diagnostics/domain/device_diagnostics.dart';
import 'package:mobile/features/vision/diagnostics/domain/pose_engine_self_test_result.dart';
import 'package:mobile/features/vision/diagnostics/domain/pose_engine_self_test_runner.dart';
import 'package:mobile/features/vision/diagnostics/presentation/providers/vision_diagnostics_controller.dart';
import 'package:mobile/features/vision/diagnostics/presentation/screens/vision_diagnostics_screen.dart';

const _device = DeviceDiagnostics(
  appVersion: '0.1.0',
  buildNumber: '1',
  platformName: 'Android',
  osVersion: 'Android 14 (API 34)',
  deviceModel: 'Google Pixel 8',
  isPhysicalDevice: true,
);

class _FakeDeviceDiagnosticsService implements DeviceDiagnosticsService {
  @override
  Future<DeviceDiagnostics> load() async => _device;
}

class _FakeSelfTestRunner implements PoseEngineSelfTestRunner {
  _FakeSelfTestRunner({this.result});

  final PoseEngineSelfTestResult? result;

  @override
  Future<PoseEngineSelfTestResult> run() async {
    return result ??
        const PoseEngineSelfTestResult(
          succeeded: true,
          message: 'Camera and on-device pose detector are both working.',
          elapsed: Duration(milliseconds: 180),
        );
  }
}

Widget _wrap({
  Future<List<CameraDescription>> Function()? camerasLoader,
  PoseEngineSelfTestRunner? selfTestRunner,
}) {
  return ProviderScope(
    overrides: [
      visionDiagnosticsControllerProvider.overrideWith(
        (ref) => VisionDiagnosticsController(
          deviceDiagnosticsService: _FakeDeviceDiagnosticsService(),
          camerasLoader:
              camerasLoader ??
              (() async => const [
                CameraDescription(
                  name: 'back-camera',
                  lensDirection: CameraLensDirection.back,
                  sensorOrientation: 90,
                ),
              ]),
          selfTestRunner: selfTestRunner ?? _FakeSelfTestRunner(),
        ),
      ),
    ],
    child: const MaterialApp(home: VisionDiagnosticsScreen()),
  );
}

void main() {
  testWidgets('shows device/build identity and camera hardware once loaded', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    expect(find.text('Device & build'), findsOneWidget);
    expect(find.text('0.1.0 (1)'), findsOneWidget);
    expect(find.text('Google Pixel 8'), findsOneWidget);
    expect(find.text('Camera hardware'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('running the self-test shows a success result', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Run self-test'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Run self-test'));
    await tester.pumpAndSettle();

    expect(
      find.text('Camera and on-device pose detector are both working.'),
      findsOneWidget,
    );
    expect(find.text('180ms'), findsOneWidget);
  });

  testWidgets('running the self-test shows an honest failure result', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        selfTestRunner: _FakeSelfTestRunner(
          result: const PoseEngineSelfTestResult(
            succeeded: false,
            message: 'Camera permission was not granted.',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Run self-test'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Run self-test'));
    await tester.pumpAndSettle();

    expect(find.text('Camera permission was not granted.'), findsOneWidget);
  });
}
