import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/diagnostics/data/device_diagnostics_service.dart';
import 'package:mobile/core/diagnostics/domain/device_diagnostics.dart';
import 'package:mobile/features/vision/diagnostics/domain/pose_engine_self_test_result.dart';
import 'package:mobile/features/vision/diagnostics/domain/pose_engine_self_test_runner.dart';
import 'package:mobile/features/vision/diagnostics/presentation/providers/vision_diagnostics_controller.dart';

const _device = DeviceDiagnostics(
  appVersion: '0.1.0',
  buildNumber: '1',
  platformName: 'Android',
  osVersion: 'Android 14 (API 34)',
  deviceModel: 'Google Pixel 8',
  isPhysicalDevice: true,
);

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

class _FakeDeviceDiagnosticsService implements DeviceDiagnosticsService {
  _FakeDeviceDiagnosticsService({this.error});

  final Object? error;

  @override
  Future<DeviceDiagnostics> load() async {
    if (error != null) throw error!;
    return _device;
  }
}

class _FakeSelfTestRunner implements PoseEngineSelfTestRunner {
  _FakeSelfTestRunner({this.result});

  PoseEngineSelfTestResult? result;
  int callCount = 0;

  @override
  Future<PoseEngineSelfTestResult> run() async {
    callCount += 1;
    return result ??
        const PoseEngineSelfTestResult(
          succeeded: true,
          message: 'Camera and on-device pose detector are both working.',
          elapsed: Duration(milliseconds: 250),
        );
  }
}

VisionDiagnosticsController _buildController({
  DeviceDiagnosticsService? deviceDiagnosticsService,
  Future<List<CameraDescription>> Function()? camerasLoader,
  PoseEngineSelfTestRunner? selfTestRunner,
}) {
  return VisionDiagnosticsController(
    deviceDiagnosticsService:
        deviceDiagnosticsService ?? _FakeDeviceDiagnosticsService(),
    camerasLoader: camerasLoader ?? (() async => [_back, _front]),
    selfTestRunner: selfTestRunner ?? _FakeSelfTestRunner(),
  );
}

void main() {
  group('VisionDiagnosticsController loading', () {
    test('loads device diagnostics and camera info on construction', () async {
      final controller = _buildController();
      await Future<void>.delayed(Duration.zero);

      expect(controller.state.loadStatus, VisionDiagnosticsLoadStatus.ready);
      expect(controller.state.deviceDiagnostics, _device);
      expect(controller.state.cameraCount, 2);
      expect(controller.state.hasFrontCamera, isTrue);
      expect(controller.state.hasBackCamera, isTrue);
    });

    test(
      'reports hasFrontCamera/hasBackCamera false when only one exists',
      () async {
        final controller = _buildController(camerasLoader: () async => [_back]);
        await Future<void>.delayed(Duration.zero);

        expect(controller.state.hasBackCamera, isTrue);
        expect(controller.state.hasFrontCamera, isFalse);
        expect(controller.state.cameraCount, 1);
      },
    );

    test(
      'an error while loading device diagnostics reports an error status, not a crash',
      () async {
        final controller = _buildController(
          deviceDiagnosticsService: _FakeDeviceDiagnosticsService(
            error: StateError('no platform channel in this test'),
          ),
        );
        await Future<void>.delayed(Duration.zero);

        expect(controller.state.loadStatus, VisionDiagnosticsLoadStatus.error);
      },
    );

    test(
      'an error while listing cameras reports an error status, not a crash',
      () async {
        final controller = _buildController(
          camerasLoader: () async => throw StateError('no camera plugin'),
        );
        await Future<void>.delayed(Duration.zero);

        expect(controller.state.loadStatus, VisionDiagnosticsLoadStatus.error);
      },
    );
  });

  group('VisionDiagnosticsController.runSelfTest', () {
    test('starts at notRun and transitions to running then done', () async {
      final runner = _FakeSelfTestRunner();
      final controller = _buildController(selfTestRunner: runner);
      await Future<void>.delayed(Duration.zero);

      expect(controller.state.selfTestStatus, PoseEngineSelfTestStatus.notRun);

      final future = controller.runSelfTest();
      expect(controller.state.selfTestStatus, PoseEngineSelfTestStatus.running);
      expect(controller.state.selfTestResult, isNull);

      await future;
      expect(controller.state.selfTestStatus, PoseEngineSelfTestStatus.done);
      expect(controller.state.selfTestResult?.succeeded, isTrue);
    });

    test('surfaces a failing self-test result honestly', () async {
      final runner = _FakeSelfTestRunner(
        result: const PoseEngineSelfTestResult(
          succeeded: false,
          message: 'Camera permission was not granted.',
        ),
      );
      final controller = _buildController(selfTestRunner: runner);
      await Future<void>.delayed(Duration.zero);

      await controller.runSelfTest();

      expect(controller.state.selfTestResult?.succeeded, isFalse);
      expect(
        controller.state.selfTestResult?.message,
        'Camera permission was not granted.',
      );
    });

    test(
      'does not start a second self-test while one is already running',
      () async {
        final runner = _FakeSelfTestRunner();
        final controller = _buildController(selfTestRunner: runner);
        await Future<void>.delayed(Duration.zero);

        final first = controller.runSelfTest();
        final second = controller.runSelfTest();
        await Future.wait([first, second]);

        expect(runner.callCount, 1);
      },
    );

    test('clears the previous result once a new self-test starts', () async {
      final runner = _FakeSelfTestRunner();
      final controller = _buildController(selfTestRunner: runner);
      await Future<void>.delayed(Duration.zero);

      await controller.runSelfTest();
      expect(controller.state.selfTestResult, isNotNull);

      final second = controller.runSelfTest();
      expect(controller.state.selfTestResult, isNull);
      await second;
    });
  });
}
