import UIKit
import AVFoundation

class CameraViewController: UIViewController {
    var captureSession: AVCaptureSession?
    var photoOutput = AVCapturePhotoOutput()
    var previewLayer: AVCaptureVideoPreviewLayer?

    var currentInput: AVCaptureDeviceInput?
    var cameraPosition: AVCaptureDevice.Position = .front

    var onImageCaptured: ((String) -> Void)? // ✅ Callback to return image

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
        setupUI()
        NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged), name: UIDevice.orientationDidChangeNotification, object: nil)
    }

    func setupUI() {
        let captureButton = UIButton(type: .system)
        captureButton.setImage(UIImage(systemName: "circle.fill"), for: .normal)
        captureButton.tintColor = .white
        captureButton.frame = CGRect(x: (view.bounds.width - 80)/2, y: view.bounds.height - 120, width: 80, height: 80)
        captureButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        view.addSubview(captureButton)

        let flipButton = UIButton(type: .system)
        flipButton.setImage(UIImage(systemName: "arrow.triangle.2.circlepath.camera"), for: .normal)
        flipButton.tintColor = .white
        flipButton.frame = CGRect(x: view.bounds.width - 60, y: 50, width: 40, height: 40)
        flipButton.addTarget(self, action: #selector(flipCamera), for: .touchUpInside)
        view.addSubview(flipButton)
    }

    func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession?.beginConfiguration()

        if let currentInput = currentInput {
            captureSession?.removeInput(currentInput)
        }

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraPosition),
              let input = try? AVCaptureDeviceInput(device: camera),
              captureSession?.canAddInput(input) == true else {
            return
        }

        currentInput = input
        captureSession?.addInput(input)

        if captureSession?.canAddOutput(photoOutput) == true {
            captureSession?.addOutput(photoOutput)
        }

        captureSession?.commitConfiguration()

        if previewLayer == nil {
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
            previewLayer?.frame = view.layer.bounds
            previewLayer?.videoGravity = .resizeAspectFill
            view.layer.insertSublayer(previewLayer!, at: 0)
        } else {
            previewLayer?.session = captureSession
        }

        captureSession?.startRunning()
    }

    @objc func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    @objc func flipCamera() {
        cameraPosition = (cameraPosition == .back) ? .front : .back
        setupCamera()
    }

    @objc func orientationChanged() {
        guard let connection = previewLayer?.connection else { return }

        switch UIDevice.current.orientation {
        case .portrait:
            connection.videoOrientation = .portrait
        case .landscapeRight:
            connection.videoOrientation = .landscapeLeft
        case .landscapeLeft:
            connection.videoOrientation = .landscapeRight
        case .portraitUpsideDown:
            connection.videoOrientation = .portraitUpsideDown
        default:
            break
        }

        previewLayer?.frame = view.bounds
    }
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation() else { return }

        let filename = "\(UUID().uuidString).jpg"
        let filePath = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        do {
            try imageData.write(to: filePath)
            onImageCaptured?(filePath.path) // ✅ Send back to Flutter
            DispatchQueue.main.async {
                self.dismiss(animated: true, completion: nil)
            }
        } catch {
            print("Error saving image: \(error)")
        }
    }
}
