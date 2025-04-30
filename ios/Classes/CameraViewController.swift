import UIKit
import AVFoundation
import Photos

class CameraViewController: UIViewController {
  var captureSession: AVCaptureSession?
  var photoOutput = AVCapturePhotoOutput()
  var previewLayer: AVCaptureVideoPreviewLayer?

  var currentInput: AVCaptureDeviceInput?
  var cameraPosition: AVCaptureDevice.Position = .front

  var onImageCaptured: ((String) -> Void)?
  var preloadedPath: String?
  var currentDevice: AVCaptureDevice?
  var flashEnabled = true // or false based on your default state

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .black

    if let path = preloadedPath {
      print("Path passed from Flutter: \(path)")
      // You can add code here to display the image if needed
    }

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

    let flashButton = UIButton(frame: CGRect(x: view.frame.width - 60, y: 40, width: 40, height: 40))
    flashButton.setImage(UIImage(systemName: "bolt.fill"), for: .normal) // Flash ON icon initially
    flashButton.tintColor = .white // Optional: sets icon color
    flashButton.addTarget(self, action: #selector(toggleFlash), for: .touchUpInside)
    view.addSubview(flashButton)

    let galleryButton = UIButton(type: .system)
    galleryButton.setImage(UIImage(systemName: "photo.on.rectangle"), for: .normal)
    galleryButton.tintColor = .white
    galleryButton.frame = CGRect(x: (view.bounds.width - 80) / 2, y: view.bounds.height - 200, width: 80, height: 80)
    galleryButton.addTarget(self, action: #selector(openGallery), for: .touchUpInside)
    view.addSubview(galleryButton)

    let flipButton = UIButton(type: .system)
    flipButton.setImage(UIImage(systemName: "arrow.triangle.2.circlepath.camera"), for: .normal)
    flipButton.tintColor = .white
    flipButton.frame = CGRect(x: view.bounds.width - 60, y: 50, width: 40, height: 40)
    flipButton.addTarget(self, action: #selector(flipCamera), for: .touchUpInside)
    view.addSubview(flipButton)
  }

  @objc func toggleFlash(_ sender: UIButton) {
      guard let device = currentDevice, device.hasTorch else { return }
          do {
              try device.lockForConfiguration()
              flashEnabled.toggle()
              device.torchMode = flashEnabled ? .on : .off
              device.unlockForConfiguration()

              let imageName = flashEnabled ? "bolt.fill" : "bolt.slash.fill"
              sender.setImage(UIImage(systemName: imageName), for: .normal)
          } catch {
              print("Flash error: \(error)")
          }
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

    currentDevice = camera

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

  @objc func openGallery() {
    let imagePickerController = UIImagePickerController()
    imagePickerController.sourceType = .photoLibrary
    imagePickerController.delegate = self
    self.present(imagePickerController, animated: true, completion: nil)
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

    let filename = preloadedPath?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? preloadedPath! :"\(UUID().uuidString).jpg"
    let filePath = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

    do {
      try imageData.write(to: filePath)
      onImageCaptured?(filePath.path)
      DispatchQueue.main.async {
        self.dismiss(animated: true, completion: nil)
      }
    } catch {
      print("Error saving image: \(error)")
    }
  }
}

extension CameraViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
    if let imageURL = info[.imageURL] as? URL {
      onImageCaptured?(imageURL.path)
    }
    picker.dismiss(animated: true, completion: nil)
  }

  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    picker.dismiss(animated: true, completion: nil)
  }
}