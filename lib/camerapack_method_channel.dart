import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'camerapack_platform_interface.dart';

/// An implementation of [CamerapackPlatform] that uses method channels.
class MethodChannelCamerapack extends CamerapackPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('imageCapture');

  @override
  Future<String?> captureImage({bool isfront = false,String? path}) async {
    // TODO: implement captureImage
    final version = await methodChannel.invokeMethod<String>('onCameraClick',{
      'cameraPosition': isfront?'front':"back",'path': path,});
      return version;
  }

  @override
  Future<String?> pickFromGallery() async {
    // TODO: implement pickFromGallery
    final version = await methodChannel.invokeMethod<String>('onGalleryClick',);
    return version;
  }


}
