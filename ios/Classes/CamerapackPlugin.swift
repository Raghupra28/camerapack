import Flutter
import UIKit
import Photos
import AVFoundation

public class CamerapackPlugin: NSObject, FlutterPlugin {

  var controller: FlutterViewController?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "imageCapture", binaryMessenger: registrar.messenger())
    let instance = CamerapackPlugin()
    instance.controller = UIApplication.shared.delegate?.window??.rootViewController as? FlutterViewController
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      if call.method == "onCameraClick",
         let args = call.arguments as? [String: Any],
         let positionString = args["cameraPosition"] as? String {

        let cameraVC = CameraViewController()
        cameraVC.modalPresentationStyle = .fullScreen
        cameraVC.cameraPosition = (positionString == "front") ? .front : .back

        if let path = args["path"] as? String {
                cameraVC.preloadedPath = path
              }

        cameraVC.onImageCaptured = { imagePath in
          result(imagePath) // ✅ Return image path to Flutter
        }

        controller?.present(cameraVC, animated: true, completion: nil)
      } else if call.method == "onGalleryClick" {
              // Handle gallery image picking
              let imagePicker = UIImagePickerController()
              imagePicker.sourceType = .photoLibrary
              imagePicker.allowsEditing = false
              imagePicker.delegate = self

              controller?.present(imagePicker, animated: true, completion: nil)

              self.pendingResult = result
            } else {
        result(FlutterMethodNotImplemented)
      }
    }

    var pendingResult: FlutterResult?

      func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImageURL = info[.imageURL] as? URL {
          let imagePath = selectedImageURL.path
          pendingResult?(imagePath) // Return the image path to Flutter
        } else {
          pendingResult?(FlutterError(code: "PICKING_FAILED", message: "Failed to pick image", details: nil))
        }

        picker.dismiss(animated: true, completion: nil)
      }

      func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
          pendingResult?(FlutterError(code: "PICKING_CANCELED", message: "Image picking was canceled", details: nil))
          picker.dismiss(animated: true, completion: nil)
        }
}
