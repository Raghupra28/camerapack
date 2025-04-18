
import 'camerapack_platform_interface.dart';

class Camerapack {
  Future<String?> captureImage({bool isfront =false}) {
    return CamerapackPlatform.instance.captureImage(isfront:isfront);
  }

  Future<String?> pickFromGallery() {
    return CamerapackPlatform.instance.pickFromGallery();
  }
}
