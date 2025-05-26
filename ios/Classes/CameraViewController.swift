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
  var backButton: UIButton!
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

// 1. Bottom Bar
      let bottomBar = UIView()
         bottomBar.backgroundColor = .black
         bottomBar.translatesAutoresizingMaskIntoConstraints = false
         view.addSubview(bottomBar)

         NSLayoutConstraint.activate([
             bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
             bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
             bottomBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
             bottomBar.heightAnchor.constraint(equalToConstant: 100)
         ])


        // 2. Capture Button
            captureButton = UIButton(type: .system)
            captureButton.setImage(UIImage(systemName: "circle.fill"), for: .normal)
            captureButton.tintColor = .white
            captureButton.backgroundColor = .white
            captureButton.layer.cornerRadius = 35
            captureButton.tag = 5002
            captureButton.translatesAutoresizingMaskIntoConstraints = false
            captureButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
            view.addSubview(captureButton)

            NSLayoutConstraint.activate([
                captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                captureButton.bottomAnchor.constraint(equalTo: bottomBar.topAnchor, constant: -15),
                captureButton.widthAnchor.constraint(equalToConstant: 70),
                captureButton.heightAnchor.constraint(equalToConstant: 70)
            ])


// 3. Gallery Button
     galleryButton = UIButton(type: .system)
        galleryButton.setImage(UIImage(systemName: "photo.on.rectangle"), for: .normal)
        galleryButton.tintColor = .white
        galleryButton.tag = 5004
        galleryButton.translatesAutoresizingMaskIntoConstraints = false
        galleryButton.addTarget(self, action: #selector(openGallery), for: .touchUpInside)
        view.addSubview(galleryButton)

        NSLayoutConstraint.activate([
            galleryButton.trailingAnchor.constraint(equalTo: captureButton.leadingAnchor, constant: -40),
            galleryButton.centerYAnchor.constraint(equalTo: captureButton.centerYAnchor),
            galleryButton.widthAnchor.constraint(equalToConstant: 40),
            galleryButton.heightAnchor.constraint(equalToConstant: 40)
        ])

// 4. Flip Camera Button
        flipButton = UIButton(type: .system)
            flipButton.setImage(UIImage(systemName: "arrow.triangle.2.circlepath.camera"), for: .normal)
            flipButton.tintColor = .white
            flipButton.tag = 5005
            flipButton.translatesAutoresizingMaskIntoConstraints = false
            flipButton.addTarget(self, action: #selector(flipCamera), for: .touchUpInside)
            view.addSubview(flipButton)

            NSLayoutConstraint.activate([
                flipButton.leadingAnchor.constraint(equalTo: captureButton.trailingAnchor, constant: 40),
                flipButton.centerYAnchor.constraint(equalTo: captureButton.centerYAnchor),
                flipButton.widthAnchor.constraint(equalToConstant: 40),
                flipButton.heightAnchor.constraint(equalToConstant: 40)
            ])


            backButton = UIButton()
                backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
                backButton.tintColor = .white
                backButton.tag = 5001
                backButton.translatesAutoresizingMaskIntoConstraints = false
                backButton.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)
                view.addSubview(backButton)

                NSLayoutConstraint.activate([
                    backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                    backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
                    backButton.widthAnchor.constraint(equalToConstant: 30),
                    backButton.heightAnchor.constraint(equalToConstant: 30)
                ])

     // 6. Flash Button (top right)
        flashButton = UIButton()
        flashButton.setImage(UIImage(systemName: "bolt.fill"), for: .normal)
        flashButton.tintColor = .white
        flashButton.tag = 5003
        flashButton.isHidden = (cameraPosition == .front)
        flashButton.translatesAutoresizingMaskIntoConstraints = false
        flashButton.addTarget(self, action: #selector(toggleFlash), for: .touchUpInside)
        view.addSubview(flashButton)

        NSLayoutConstraint.activate([
            flashButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            flashButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            flashButton.widthAnchor.constraint(equalToConstant: 30),
            flashButton.heightAnchor.constraint(equalToConstant: 30)
        ])
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
                  view.bringSubviewToFront(backButton)
  }

  @objc func dismissSelf() {
      self.dismiss(animated: true, completion: nil)
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