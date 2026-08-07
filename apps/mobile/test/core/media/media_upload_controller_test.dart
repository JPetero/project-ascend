import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/media/data/media_picker_service.dart';
import 'package:mobile/core/media/domain/media_type.dart';
import 'package:mobile/core/media/presentation/providers/media_upload_controller.dart';

import '../../helpers/fake_media_picker_service.dart';
import '../../helpers/fake_media_repository.dart';

void main() {
  late FakeMediaRepository repository;
  late FakeMediaPickerService picker;
  late MediaUploadController controller;

  const pickedImage = PickedMediaFile(
    path: '/tmp/photo.jpg',
    filename: 'photo.jpg',
    mimeType: 'image/jpeg',
    sizeBytes: 4,
  );

  setUp(() {
    repository = FakeMediaRepository();
    picker = FakeMediaPickerService(fileToReturn: pickedImage);
    controller = MediaUploadController(
      repository: repository,
      pickerService: picker,
      fileReader: FakeMediaFileReader(),
    );
  });

  tearDown(() {
    controller.dispose();
  });

  test('starts idle', () {
    expect(controller.state.status, MediaUploadStatus.idle);
  });

  test('picking from gallery uploads and completes', () async {
    await controller.pickImageFromGallery(AscendMediaType.communityImage);

    expect(controller.state.status, MediaUploadStatus.completed);
    expect(controller.state.mediaAssetId, isNotNull);
    expect(controller.state.progress, 1);
    expect(repository.uploadCount, 1);
  });

  test(
    'does nothing when the picker returns no file (user cancelled the OS sheet)',
    () async {
      picker.fileToReturn = null;

      await controller.pickImageFromGallery(AscendMediaType.communityImage);

      expect(controller.state.status, MediaUploadStatus.idle);
    },
  );

  test(
    'denied camera permission surfaces an honest message, never invokes the camera',
    () async {
      picker.permissionStatus = MediaPermissionStatus.denied;

      await controller.captureImageFromCamera(AscendMediaType.communityImage);

      expect(controller.state.status, MediaUploadStatus.permissionDenied);
      expect(repository.uploadCount, 0);
    },
  );

  test(
    'permanently denied camera permission gets a settings-pointing message',
    () async {
      picker.permissionStatus = MediaPermissionStatus.permanentlyDenied;

      await controller.captureImageFromCamera(AscendMediaType.communityImage);

      expect(controller.state.status, MediaUploadStatus.permissionDenied);
      expect(controller.state.error, contains('system settings'));
    },
  );

  test('granted camera permission uploads the captured file', () async {
    await controller.captureImageFromCamera(AscendMediaType.communityImage);

    expect(controller.state.status, MediaUploadStatus.completed);
  });

  test(
    'a failed upload can be retried and succeeds once the failure clears',
    () async {
      repository.failUpload = true;

      await controller.pickImageFromGallery(AscendMediaType.communityImage);
      expect(controller.state.status, MediaUploadStatus.failed);

      repository.failUpload = false;
      await controller.retry();

      expect(controller.state.status, MediaUploadStatus.completed);
    },
  );

  test('reset returns to idle and clears the picked file', () async {
    await controller.pickImageFromGallery(AscendMediaType.communityImage);
    expect(controller.state.status, MediaUploadStatus.completed);

    controller.reset();

    expect(controller.state.status, MediaUploadStatus.idle);
    expect(controller.state.pickedFile, isNull);
  });
}
