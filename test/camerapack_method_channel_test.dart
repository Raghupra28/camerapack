import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:camerapack/camerapack_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelCamerapack platform = MethodChannelCamerapack();
  const MethodChannel channel = MethodChannel('camerapack');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.captureImage(), '42');
  });
}
