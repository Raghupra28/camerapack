import 'package:flutter_test/flutter_test.dart';
import 'package:camerapack/camerapack.dart';
import 'package:camerapack/camerapack_platform_interface.dart';
import 'package:camerapack/camerapack_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockCamerapackPlatform
    with MockPlatformInterfaceMixin
    implements CamerapackPlatform {

  @override
  Future<String?> captureImage({bool isfront = false,String? path}) {
    // TODO: implement captureImage
   return Future.value('28');
  }

  @override
  Future<String?> pickFromGallery() {
    // TODO: implement pickFromGallery
    return Future.value('2828');
  }
}

void main() {
  final CamerapackPlatform initialPlatform = CamerapackPlatform.instance;

  test('$MethodChannelCamerapack is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelCamerapack>());
  });

  test('getPlatformVersion', () async {
    Camerapack camerapackPlugin = Camerapack();
    MockCamerapackPlatform fakePlatform = MockCamerapackPlatform();
    CamerapackPlatform.instance = fakePlatform;

    expect(await camerapackPlugin.captureImage(), '28');
    expect(await camerapackPlugin.pickFromGallery(), '28');
  });
}
