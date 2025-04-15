import Flutter
import UIKit

public class CamerapackPlugin: NSObject, FlutterPlugin {

  var controller: FlutterViewController?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "imageCapture", binaryMessenger: registrar.messenger())
    let instance = CamerapackPlugin()
    instance.controller = UIApplication.shared.delegate?.window??.rootViewController as? FlutterViewController
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      if call.method == "oncameraClick",
         let args = call.arguments as? [String: Any],
         let positionString = args["cameraPosition"] as? String {

        let cameraVC = CameraViewController()
        cameraVC.modalPresentationStyle = .fullScreen
        cameraVC.cameraPosition = (positionString == "front") ? .front : .back
        cameraVC.onImageCaptured = { imagePath in
          result(imagePath) // ✅ Return image path to Flutter
        }

        controller?.present(cameraVC, animated: true, completion: nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
}
