import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'camerapack_method_channel.dart';

abstract class CamerapackPlatform extends PlatformInterface {
  /// Constructs a CamerapackPlatform.
  CamerapackPlatform() : super(token: _token);

  static final Object _token = Object();

  static CamerapackPlatform _instance = MethodChannelCamerapack();

  /// The default instance of [CamerapackPlatform] to use.
  ///
  /// Defaults to [MethodChannelCamerapack].
  static CamerapackPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [CamerapackPlatform] when
  /// they register themselves.
  static set instance(CamerapackPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> captureImage({bool isfront =false}) {
    throw UnimplementedError('captureImage() has not been implemented.');
  }
}
