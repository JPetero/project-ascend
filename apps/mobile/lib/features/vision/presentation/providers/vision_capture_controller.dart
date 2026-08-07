import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/media/data/media_picker_service.dart';
import '../../../../core/media/presentation/providers/media_upload_controller.dart';
import '../../domain/vision_module.dart';

enum VisionCaptureStatus {
  idle,
  requestingPermission,
  permissionDenied,
  permissionPermanentlyDenied,
  capturing,
  captured,
  error,
}

class VisionCaptureState {
  const VisionCaptureState({
    this.status = VisionCaptureStatus.idle,
    this.file,
    this.errorMessage,
  });

  final VisionCaptureStatus status;
  final PickedMediaFile? file;
  final String? errorMessage;

  VisionCaptureState copyWith({
    VisionCaptureStatus? status,
    PickedMediaFile? file,
    String? errorMessage,
  }) {
    return VisionCaptureState(
      status: status ?? this.status,
      file: file ?? this.file,
      errorMessage: errorMessage,
    );
  }
}

/// Drives a single Vision mode's "try the camera" flow — Build Session
/// 8 Part 16. Real permission request and real capture through the same
/// [MediaPickerService] the Media Platform (Part 3) already uses;
/// nothing captured here is uploaded, stored, or analyzed. Every
/// capture re-requests permission rather than caching a "trusted"
/// flag on our side, so the OS consent flow is always the source of
/// truth for whether camera access is currently allowed.
class VisionCaptureController extends StateNotifier<VisionCaptureState> {
  VisionCaptureController({
    required MediaPickerService pickerService,
    required VisionModule module,
  }) : _pickerService = pickerService,
       _module = module,
       super(const VisionCaptureState());

  final MediaPickerService _pickerService;
  final VisionModule _module;

  Future<void> capture() async {
    state = state.copyWith(
      status: VisionCaptureStatus.requestingPermission,
      errorMessage: null,
    );

    final permission = await _pickerService.requestCameraPermission();
    if (permission == MediaPermissionStatus.permanentlyDenied) {
      state = state.copyWith(
        status: VisionCaptureStatus.permissionPermanentlyDenied,
      );
      return;
    }
    if (permission == MediaPermissionStatus.denied) {
      state = state.copyWith(status: VisionCaptureStatus.permissionDenied);
      return;
    }

    state = state.copyWith(status: VisionCaptureStatus.capturing);
    try {
      final file = visionModuleCapturesVideo(_module)
          ? await _pickerService.captureVideoFromCamera(
              maxDuration: const Duration(seconds: 15),
            )
          : await _pickerService.captureImageFromCamera();
      if (file == null) {
        state = state.copyWith(status: VisionCaptureStatus.idle);
        return;
      }
      state = state.copyWith(status: VisionCaptureStatus.captured, file: file);
    } catch (error) {
      state = state.copyWith(
        status: VisionCaptureStatus.error,
        errorMessage: error.toString(),
      );
    }
  }

  void discard() {
    state = const VisionCaptureState();
  }
}

final visionCaptureControllerProvider = StateNotifierProvider.autoDispose
    .family<VisionCaptureController, VisionCaptureState, VisionModule>((
      ref,
      module,
    ) {
      return VisionCaptureController(
        pickerService: ref.watch(mediaPickerServiceProvider),
        module: module,
      );
    });
