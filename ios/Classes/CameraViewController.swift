import UIKit
import AVFoundation
import Photos

class CameraViewController: UIViewController {
    
    // MARK: - Camera Properties
    private var captureSession: AVCaptureSession?
    private var photoOutput = AVCapturePhotoOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var currentInput: AVCaptureDeviceInput?
    private var currentDevice: AVCaptureDevice?
    
    // MARK: - UI Elements
    private var captureButton: UIButton!
    private var backButton: UIButton!
    private var flashButton: UIButton!
    private var flipButton: UIButton!
    private var galleryButton: UIButton!
    
    // MARK: - Variables
    var cameraPosition: AVCaptureDevice.Position = .front
    var onImageCaptured: ((String) -> Void)?
    var preloadedPath: String?
    private var flashEnabled = true
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        if let path = preloadedPath {
            print("Preloaded path from Flutter: \(path)")
        }
        
        checkCameraPermission()
        setupUI()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(orientationChanged),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        captureSession?.stopRunning()
    }
    
    // MARK: - Permissions
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    granted ? self.setupCamera() : self.showPermissionDeniedAlert()
                }
            }
        default:
            showPermissionDeniedAlert()
        }
    }
    
    private func showPermissionDeniedAlert() {
        let alert = UIAlertController(
            title: "Camera Access Denied",
            message: "Please enable camera access in Settings to use this feature.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default, handler: { _ in
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsUrl)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    // MARK: - UI Setup
    private func setupUI() {
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
        
        // Capture button
        captureButton = UIButton(type: .system)
        captureButton.setImage(UIImage(systemName: "circle.fill"), for: .normal)
        captureButton.tintColor = .white
        captureButton.backgroundColor = .white
        captureButton.layer.cornerRadius = 35
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        captureButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
        view.addSubview(captureButton)
        
        NSLayoutConstraint.activate([
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.bottomAnchor.constraint(equalTo: bottomBar.topAnchor, constant: -15),
            captureButton.widthAnchor.constraint(equalToConstant: 70),
            captureButton.heightAnchor.constraint(equalToConstant: 70)
        ])
        
        // Gallery button
        galleryButton = UIButton(type: .system)
        galleryButton.setImage(UIImage(systemName: "photo.on.rectangle"), for: .normal)
        galleryButton.tintColor = .white
        galleryButton.translatesAutoresizingMaskIntoConstraints = false
        galleryButton.addTarget(self, action: #selector(openGallery), for: .touchUpInside)
        view.addSubview(galleryButton)
        
        NSLayoutConstraint.activate([
            galleryButton.trailingAnchor.constraint(equalTo: captureButton.leadingAnchor, constant: -40),
            galleryButton.centerYAnchor.constraint(equalTo: captureButton.centerYAnchor),
            galleryButton.widthAnchor.constraint(equalToConstant: 40),
            galleryButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        // Flip button
        flipButton = UIButton(type: .system)
        flipButton.setImage(UIImage(systemName: "arrow.triangle.2.circlepath.camera"), for: .normal)
        flipButton.tintColor = .white
        flipButton.translatesAutoresizingMaskIntoConstraints = false
        flipButton.addTarget(self, action: #selector(flipCamera), for: .touchUpInside)
        view.addSubview(flipButton)
        
        NSLayoutConstraint.activate([
            flipButton.leadingAnchor.constraint(equalTo: captureButton.trailingAnchor, constant: 40),
            flipButton.centerYAnchor.constraint(equalTo: captureButton.centerYAnchor),
            flipButton.widthAnchor.constraint(equalToConstant: 40),
            flipButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        // Back button
        backButton = UIButton()
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = .white
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)
        view.addSubview(backButton)
        
        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            backButton.widthAnchor.constraint(equalToConstant: 30),
            backButton.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        // Flash button
        flashButton = UIButton()
        flashButton.setImage(UIImage(systemName: "bolt.fill"), for: .normal)
        flashButton.tintColor = .white
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
    
    // MARK: - Camera Setup
    private func setupCamera() {
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
        
        // 🔧 Ensure UI always appears on top (important after switching cameras)
        DispatchQueue.main.async {
            self.bringUIToFront()
        }
    }
    
    // MARK: - Actions
    @objc private func toggleFlash(_ sender: UIButton) {
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
    
    @objc private func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    @objc private func openGallery() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        present(picker, animated: true)
    }
    
    @objc private func flipCamera() {
        cameraPosition = (cameraPosition == .back) ? .front : .back
        setupCamera()
        
        // Small delay ensures preview layer finishes rendering before bringing UI to front
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.bringUIToFront()
        }
    }
    
    @objc private func dismissSelf() {
        dismiss(animated: true)
    }
    
    private func bringUIToFront() {
        [captureButton, flipButton, flashButton, galleryButton, backButton].forEach {
            view.bringSubviewToFront($0)
        }
    }
    
    // MARK: - Orientation Handling
    @objc private func orientationChanged() {
        guard let connection = previewLayer?.connection else { return }
        switch UIDevice.current.orientation {
        case .portrait: connection.videoOrientation = .portrait
        case .landscapeRight: connection.videoOrientation = .landscapeLeft
        case .landscapeLeft: connection.videoOrientation = .landscapeRight
        case .portraitUpsideDown: connection.videoOrientation = .portraitUpsideDown
        default: break
        }
        previewLayer?.frame = view.bounds
    }
}

// MARK: - Photo Capture Delegate
extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation() else { return }
        
        let filename = preloadedPath?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            ? preloadedPath!
            : "\(UUID().uuidString).jpg"
        let filePath = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        
        do {
            try imageData.write(to: filePath, options: .atomic)
            onImageCaptured?(filePath.path)
            DispatchQueue.main.async { self.dismiss(animated: true) }
        } catch {
            print("Error saving image: \(error)")
        }
    }
}

// MARK: - Gallery Picker Delegate
extension CameraViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        var imagePath: String?
        
        if let imageURL = info[.imageURL] as? URL {
            imagePath = imageURL.path
        } else if let image = info[.originalImage] as? UIImage {
            let fileName = UUID().uuidString + ".png"
            let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            if let data = image.pngData() {
                try? data.write(to: fileURL, options: .atomic)
                imagePath = fileURL.path
            }
        }
        
        if let finalPath = imagePath {
            onImageCaptured?(finalPath)
        }
        picker.dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
