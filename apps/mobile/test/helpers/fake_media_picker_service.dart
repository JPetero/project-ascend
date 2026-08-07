import 'package:mobile/core/media/data/media_picker_service.dart';

class FakeMediaPickerService implements MediaPickerService {
  FakeMediaPickerService({
    this.permissionStatus = MediaPermissionStatus.granted,
    this.fileToReturn,
  });

  MediaPermissionStatus permissionStatus;
  PickedMediaFile? fileToReturn;

  @override
  Future<MediaPermissionStatus> requestCameraPermission() async {
    return permissionStatus;
  }

  @override
  Future<PickedMediaFile?> pickImageFromGallery() async => fileToReturn;

  @override
  Future<PickedMediaFile?> captureImageFromCamera() async => fileToReturn;

  @override
  Future<PickedMediaFile?> pickVideoFromGallery({
    Duration? maxDuration,
  }) async => fileToReturn;

  @override
  Future<PickedMediaFile?> captureVideoFromCamera({
    Duration? maxDuration,
  }) async => fileToReturn;
}

class FakeMediaFileReader implements MediaFileReader {
  FakeMediaFileReader({List<int>? bytes}) : bytes = bytes ?? [1, 2, 3, 4];

  final List<int> bytes;

  @override
  Future<List<int>> readBytes(String path) async => bytes;
}
