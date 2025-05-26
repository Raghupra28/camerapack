import UIKit
import AVFoundation
import Photos

class CameraViewController: UIViewController {
  var captureSession: AVCaptureSession?
  var photoOutput = AVCapturePhotoOutput()
  var previewLayer: AVCaptureVideoPreviewLayer?

  var currentInput: AVCaptureDeviceInput?
  var cameraPosition: AVCaptureDevice.Position = .front
  var captureButton: UIButton!
  var flashButton: UIButton!
  var flipButton: UIButton!
  var galleryButton: UIButton!
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

    checkCameraPermission()
    setupUI()
    NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged), name: UIDevice.orientationDidChangeNotification, object: nil)
  }


  private func checkCameraPermission() {
      switch AVCaptureDevice.authorizationStatus(for: .video) {
      case .authorized:
          setupCamera()
      case .notDetermined:
          AVCaptureDevice.requestAccess(for: .video) { granted in
              if granted {
                  DispatchQueue.main.async {
                      self.setupCamera()
                  }
              } else {
                  self.showPermissionDeniedAlert()
              }
          }
      case .denied, .restricted:
          showPermissionDeniedAlert()
      @unknown default:
          break
      }
  }

  private func showPermissionDeniedAlert() {
      DispatchQueue.main.async {
          let alert = UIAlertController(title: "Camera Access Denied",
                                        message: "Please enable camera access in Settings to use this feature.",
                                        preferredStyle: .alert)
          alert.addAction(UIAlertAction(title: "Open Settings", style: .default, handler: { _ in
              if let settingsUrl = URL(string: UIApplication.openSettingsURLString),
                 UIApplication.shared.canOpenURL(settingsUrl) {
                  UIApplication.shared.open(settingsUrl)
              }
          }))
          alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
          self.present(alert, animated: true)
      }
  }


  func setupUI() {
    captureButton = UIButton(type: .system)
    captureButton.setImage(UIImage(systemName: "circle.fill"), for: .normal)
    captureButton.tintColor = .white
            captureButton.tag = 5002
    captureButton.frame = CGRect(x: (view.bounds.width - 80)/2, y: view.bounds.height - 120, width: 80, height: 80)
    captureButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
    view.addSubview(captureButton)

    flashButton = UIButton(frame: CGRect(x: view.frame.width - 60, y: 40, width: 40, height: 40))
    flashButton.setImage(UIImage(systemName: "bolt.fill"), for: .normal) // Flash ON icon initially
    flashButton.tintColor = .white // Optional: sets icon color
                flashButton.tag = 5003
                flashButton.isHidden = (cameraPosition == .front)
    flashButton.addTarget(self, action: #selector(toggleFlash), for: .touchUpInside)
    view.addSubview(flashButton)

    galleryButton = UIButton(type: .system)
    galleryButton.setImage(UIImage(systemName: "photo.on.rectangle"), for: .normal)
    galleryButton.tintColor = .white
                    galleryButton.tag = 5004
    galleryButton.frame = CGRect(x: (view.bounds.width - 80) / 2, y: view.bounds.height - 200, width: 80, height: 80)
    galleryButton.addTarget(self, action: #selector(openGallery), for: .touchUpInside)
    view.addSubview(galleryButton)

    flipButton = UIButton(type: .system)
    flipButton.setImage(UIImage(systemName: "arrow.triangle.2.circlepath.camera"), for: .normal)
    flipButton.tintColor = .white
                        flipButton.tag = 5005
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
      previewLayer?.connection?.automaticallyAdjustsVideoMirroring = false
      previewLayer?.connection?.isVideoMirrored = (cameraPosition == .front)
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
    bringUIToFront()
  }

  func bringUIToFront() {
              view.bringSubviewToFront(captureButton)
                  view.bringSubviewToFront(flipButton)
                  view.bringSubviewToFront(flashButton)
                  view.bringSubviewToFront(galleryButton)
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
      try imageData.write(to: filePath,options: .atomic)
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
      var imagePath: String?

      if let imageURL = info[.imageURL] as? URL {
          // Direct file path (no compression)
          imagePath = imageURL.path
      } else if let image = info[.originalImage] as? UIImage {
          // Save as PNG to avoid compression
          let fileName = UUID().uuidString + ".png"
          let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

          if let imageData = image.pngData() {
              do {
                  try imageData.write(to: fileURL, options: .atomic)
                  imagePath = fileURL.path
              } catch {
                  print("Error saving uncompressed image: \(error)")
              }
          }
      }

      if let finalPath = imagePath {
          onImageCaptured?(finalPath)
      }

      picker.dismiss(animated: true, completion: nil)
  }


  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    picker.dismiss(animated: true, completion: nil)
  }
}