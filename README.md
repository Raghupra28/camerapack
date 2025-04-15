📸 camerapack
camerapack is a Flutter plugin that opens a native camera screen (iOS and Android), captures a photo using the front or back camera, and returns the image path to Flutter. It also allows picking an image from the gallery.

🚀 Features
Open native camera screen (Android/iOS)
Flip between front and back cameras
Handle device orientation changes
Capture and return  image file path
Pick image from gallery
Communication between Flutter and native via platform channels

📱 Platform Support
Platform	Support
Android	      ✅
iOS	          ✅

🔧 Installation
Add the plugin to your pubspec.yaml:


🛠 Usage
Import the package
import 'package:camerapack/camerapack.dart';

Capture an Image
final camerapack = Camerapack();

Future<void> _captureImage() async {
try {
final imagePath = await camerapack.captureImage(isfront: true); // true for front camera
print('Captured image: $imagePath');
} catch (e) {
print('Error capturing image: $e');
}
}

📂 iOS Configuration
In Info.plist, add the following permissions:

<key>NSCameraUsageDescription</key>
<string>We need camera access to take pictures.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to the photo library to choose pictures.</string>

📂 Android Configuration
Make sure you have these permissions in your AndroidManifest.xml:
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
Also, make sure your minSdkVersion is at least 21.

🧑‍💻 Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

📄 License
This plugin is licensed under the Apache 2.0 License.

