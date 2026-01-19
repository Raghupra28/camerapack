import Flutter
import UIKit
import Photos
import AVFoundation

public class CamerapackPlugin: NSObject, FlutterPlugin, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    private var controller: FlutterViewController?
    private var pendingResult: FlutterResult?

    // MARK: - Plugin Registration
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "imageCapture", binaryMessenger: registrar.messenger())
        let instance = CamerapackPlugin()
        instance.controller = UIApplication.shared.delegate?.window??.rootViewController as? FlutterViewController
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    // MARK: - Method Call Handling
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "onCameraClick":
            guard let args = call.arguments as? [String: Any],
                  let positionString = args["cameraPosition"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing cameraPosition", details: nil))
                return
            }

            let cameraVC = CameraViewController()
            cameraVC.modalPresentationStyle = .fullScreen
            cameraVC.cameraPosition = (positionString == "front") ? .front : .back

            if let path = args["path"] as? String {
                cameraVC.preloadedPath = path
            }

            cameraVC.onImageCaptured = { imagePath in
                DispatchQueue.main.async {
                    result(imagePath)
                }
            }

            controller?.present(cameraVC, animated: true, completion: nil)

        case "onGalleryClick":
            DispatchQueue.main.async {
                let imagePicker = UIImagePickerController()
                imagePicker.sourceType = .photoLibrary
                imagePicker.allowsEditing = false
                imagePicker.delegate = self

                self.pendingResult = result
                self.controller?.present(imagePicker, animated: true, completion: nil)
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - UIImagePickerControllerDelegate
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        defer { 
            picker.dismiss(animated: true, completion: nil)
            pendingResult = nil
        }

        if let selectedImageURL = info[.imageURL] as? URL {
            DispatchQueue.main.async {
                self.pendingResult?(selectedImageURL.path)
            }
        } else {
            DispatchQueue.main.async {
                self.pendingResult?(FlutterError(code: "PICKING_FAILED", message: "Failed to pick image", details: nil))
            }
        }
    }

    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        DispatchQueue.main.async {
            self.pendingResult?(FlutterError(code: "PICKING_CANCELED", message: "Image picking was canceled", details: nil))
        }
        picker.dismiss(animated: true, completion: nil)
        pendingResult = nil
    }
}
