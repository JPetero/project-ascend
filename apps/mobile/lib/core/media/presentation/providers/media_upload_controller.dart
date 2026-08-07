import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../errors/app_exception.dart';
import '../../../providers/core_providers.dart';
import '../../data/media_picker_service.dart';
import '../../data/media_repository.dart';
import '../../domain/media_type.dart';

final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  return MediaRepository(apiClient: ref.watch(apiClientProvider));
});

final mediaPickerServiceProvider = Provider<MediaPickerService>((ref) {
  return ImagePickerMediaService();
});

final mediaFileReaderProvider = Provider<MediaFileReader>((ref) {
  return const MediaFileReader();
});

enum MediaUploadStatus {
  idle,
  permissionDenied,
  uploading,
  completed,
  failed,
  cancelled,
}

class MediaUploadState {
  const MediaUploadState({
    this.status = MediaUploadStatus.idle,
    this.pickedFile,
    this.progress = 0,
    this.mediaAssetId,
    this.error,
  });

  final MediaUploadStatus status;
  final PickedMediaFile? pickedFile;
  final double progress;
  final String? mediaAssetId;
  final String? error;

  bool get isBusy => status == MediaUploadStatus.uploading;

  MediaUploadState copyWith({
    MediaUploadStatus? status,
    PickedMediaFile? pickedFile,
    double? progress,
    String? mediaAssetId,
    String? error,
    bool clearError = false,
  }) {
    return MediaUploadState(
      status: status ?? this.status,
      pickedFile: pickedFile ?? this.pickedFile,
      progress: progress ?? this.progress,
      mediaAssetId: mediaAssetId ?? this.mediaAssetId,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Reusable pick → upload → retry/cancel flow — Build Session 8 Part 3.
/// A single instance handles one attachment slot; feature screens that
/// need more than one (e.g. a multi-photo post) create one controller
/// per slot rather than this class tracking a list internally.
class MediaUploadController extends StateNotifier<MediaUploadState> {
  MediaUploadController({
    required MediaRepository repository,
    required MediaPickerService pickerService,
    required MediaFileReader fileReader,
  }) : _repository = repository,
       _pickerService = pickerService,
       _fileReader = fileReader,
       super(const MediaUploadState());

  final MediaRepository _repository;
  final MediaPickerService _pickerService;
  final MediaFileReader _fileReader;
  CancelToken? _cancelToken;
  AscendMediaType? _mediaType;

  Future<void> pickImageFromGallery(AscendMediaType mediaType) async {
    final file = await _pickerService.pickImageFromGallery();
    if (file == null) return;
    await _startUpload(file, mediaType);
  }

  Future<void> captureImageFromCamera(AscendMediaType mediaType) async {
    if (!await _ensureCameraPermission()) return;
    final file = await _pickerService.captureImageFromCamera();
    if (file == null) return;
    await _startUpload(file, mediaType);
  }

  Future<void> pickVideoFromGallery(
    AscendMediaType mediaType, {
    Duration? maxDuration,
  }) async {
    final file = await _pickerService.pickVideoFromGallery(
      maxDuration: maxDuration,
    );
    if (file == null) return;
    await _startUpload(file, mediaType);
  }

  Future<void> captureVideoFromCamera(
    AscendMediaType mediaType, {
    Duration? maxDuration,
  }) async {
    if (!await _ensureCameraPermission()) return;
    final file = await _pickerService.captureVideoFromCamera(
      maxDuration: maxDuration,
    );
    if (file == null) return;
    await _startUpload(file, mediaType);
  }

  Future<bool> _ensureCameraPermission() async {
    final status = await _pickerService.requestCameraPermission();
    if (status == MediaPermissionStatus.granted) return true;
    state = state.copyWith(
      status: MediaUploadStatus.permissionDenied,
      error: status == MediaPermissionStatus.permanentlyDenied
          ? 'Camera access is off for Ascend. Enable it in system settings to take a photo or video.'
          : 'Camera access is needed to take a photo or video.',
    );
    return false;
  }

  Future<void> retry() async {
    final file = state.pickedFile;
    final mediaType = _mediaType;
    if (file == null || mediaType == null) return;
    await _startUpload(file, mediaType);
  }

  void cancel() {
    _cancelToken?.cancel();
  }

  void reset() {
    state = const MediaUploadState();
  }

  Future<void> _startUpload(
    PickedMediaFile file,
    AscendMediaType mediaType,
  ) async {
    _mediaType = mediaType;
    state = MediaUploadState(
      status: MediaUploadStatus.uploading,
      pickedFile: file,
      progress: 0,
    );
    _cancelToken = CancelToken();

    try {
      final bytes = await _fileReader.readBytes(file.path);
      final handle = await _repository.initiateUpload(
        mediaType: mediaType,
        originalFilename: file.filename,
        mimeType: file.mimeType,
        sizeBytes: bytes.length,
      );
      await _repository.uploadLocalBytes(
        mediaAssetId: handle.mediaAssetId,
        bytes: bytes,
        cancelToken: _cancelToken,
        onSendProgress: (sent, total) {
          if (total <= 0) return;
          state = state.copyWith(progress: sent / total);
        },
      );
      state = state.copyWith(
        status: MediaUploadStatus.completed,
        mediaAssetId: handle.mediaAssetId,
        progress: 1,
      );
    } catch (error) {
      if (error is AppException && error.code == 'CANCELLED') {
        state = state.copyWith(status: MediaUploadStatus.cancelled);
        return;
      }
      state = state.copyWith(
        status: MediaUploadStatus.failed,
        error: error.toString(),
      );
    }
  }
}

final mediaUploadControllerProvider =
    StateNotifierProvider.autoDispose<MediaUploadController, MediaUploadState>((
      ref,
    ) {
      return MediaUploadController(
        repository: ref.watch(mediaRepositoryProvider),
        pickerService: ref.watch(mediaPickerServiceProvider),
        fileReader: ref.watch(mediaFileReaderProvider),
      );
    });
