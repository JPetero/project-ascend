import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:permission_handler/permission_handler.dart';

class PickedMediaFile {
  const PickedMediaFile({
    required this.path,
    required this.filename,
    required this.mimeType,
    required this.sizeBytes,
    this.isVideo = false,
  });

  final String path;
  final String filename;
  final String mimeType;
  final int sizeBytes;
  final bool isVideo;
}

enum MediaPermissionStatus { granted, denied, permanentlyDenied }

/// One reusable picker/camera layer — Build Session 8 Part 3. Every
/// feature that lets a user attach a photo or video (Community,
/// profile, Trainer Groups chat, Fuel, Vision) goes through this
/// interface rather than each wiring its own `image_picker` call, so
/// permission handling and file metadata extraction only exist once.
///
/// `flutter test`'s environment has no platform channels and cannot
/// actually invoke a camera or photo library — this interface exists
/// precisely so screens/controllers can be tested against a fake
/// implementation instead. `ImagePickerMediaService` is the real
/// implementation; its own device behavior is not verifiable from an
/// automated test run in this environment (see build-session-8.md's
/// platform-limitations section).
abstract class MediaPickerService {
  Future<MediaPermissionStatus> requestCameraPermission();

  Future<PickedMediaFile?> pickImageFromGallery();

  Future<PickedMediaFile?> captureImageFromCamera();

  Future<PickedMediaFile?> pickVideoFromGallery({Duration? maxDuration});

  Future<PickedMediaFile?> captureVideoFromCamera({Duration? maxDuration});
}

class ImagePickerMediaService implements MediaPickerService {
  ImagePickerMediaService({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<MediaPermissionStatus> requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) return MediaPermissionStatus.granted;
    if (status.isPermanentlyDenied) {
      return MediaPermissionStatus.permanentlyDenied;
    }
    return MediaPermissionStatus.denied;
  }

  @override
  Future<PickedMediaFile?> pickImageFromGallery() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    return _toPickedFile(file, isVideo: false);
  }

  @override
  Future<PickedMediaFile?> captureImageFromCamera() async {
    final file = await _picker.pickImage(source: ImageSource.camera);
    return _toPickedFile(file, isVideo: false);
  }

  @override
  Future<PickedMediaFile?> pickVideoFromGallery({Duration? maxDuration}) async {
    final file = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: maxDuration,
    );
    return _toPickedFile(file, isVideo: true);
  }

  @override
  Future<PickedMediaFile?> captureVideoFromCamera({
    Duration? maxDuration,
  }) async {
    final file = await _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: maxDuration,
    );
    return _toPickedFile(file, isVideo: true);
  }

  Future<PickedMediaFile?> _toPickedFile(
    XFile? file, {
    required bool isVideo,
  }) async {
    if (file == null) return null;
    final sizeBytes = await file.length();
    final mimeType =
        file.mimeType ??
        lookupMimeType(file.path) ??
        (isVideo ? 'video/mp4' : 'image/jpeg');
    return PickedMediaFile(
      path: file.path,
      filename: file.name,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
      isVideo: isVideo,
    );
  }
}

/// Reads bytes off disk for a picked file — a thin seam so tests never
/// touch the real filesystem.
class MediaFileReader {
  const MediaFileReader();

  Future<List<int>> readBytes(String path) => File(path).readAsBytes();
}
