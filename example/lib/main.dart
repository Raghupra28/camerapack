import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camerapack/camerapack.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? imagePath;
  final _camerapack = Camerapack();

  Future<void> _captureImage() async {
    await _requestPermissions();
    try {
      final path = await _camerapack.captureImage(isfront: true);
      if (mounted && path != null) {
        setState(() {
          imagePath = path;
        });
      }
    } on PlatformException catch (e) {
      debugPrint('Failed to capture image: $e');
    }
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final storageStatus = await Permission.storage.request();
      final photosStatus = await Permission.photos.request(); // iOS support
      if (!storageStatus.isGranted && !photosStatus.isGranted) {
        debugPrint('Permissions not granted');
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    await _requestPermissions();
    try {
      final path = await _camerapack.pickFromGallery();
      if (path != null) {
        setState(() {
          imagePath = path;
        });
      }
    } catch (e) {
      print("Error picking image from gallery: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _captureImage,
                  child: Text("Capture Photo"),
                ),
                ElevatedButton(
                  onPressed: _pickImageFromGallery,
                  child: Text("Pick from Gallery"),
                ),
                const SizedBox(height: 20),
                if (imagePath != null)
                  Image.file(
                    File(imagePath!),
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
