## [0.0.7] - 2026-01-19
### Added

- iOS: Added persistent button visibility when switching between front and back cameras.

- iOS: Improved flash toggle functionality for rear camera.

- iOS: Enhanced UI layout handling for dynamic orientation and device rotation.

- Android & iOS: Optimized image capture flow with smoother transition between camera states.

### Fixed

- Fixed issue where camera control buttons disappeared after flipping the camera.

- Fixed minor layout inconsistencies in CameraViewController.

- General stability and performance improvements across both platforms.

### Changed

- Updated README.md with full usage examples and clearer documentation.

- Code cleanup and UI refactoring for improved maintainability.

---

## [0.0.6] - 2025-05-26
### Changed
- Updated Readme.

---

## [0.0.5] - 2025-05-26
### Added
- iOS: Support for image capture without compression.
- iOS: Integration with `UIImagePickerController` for optional gallery capture fallback.
- iOS: `onImageCaptured` callback now returns uncompressed image file path.

### Changed
- iOS: Internal image saving logic refactored to use `imageData.write(to:)` for full-quality preservation.

---

## [0.0.4] - 2025-04-30
### Added
- Flash toggle support for native camera screens on both Android and iOS.
- Automatically updates the flash icon based on current flash state.

### Changed
- Internal refactoring for better flash control and UI feedback.

---

## [0.0.3] - 2025-04-18
### Added
- iOS support for picking images from the gallery.
- Improved camera preview UI for better user experience on both Android and iOS.

### Fixed
- Minor bug fixes and performance improvements.
- Fixed an issue where the camera feed was not displaying properly on certain devices.

---

## [0.0.2] - 2025-04-15
### Added
- Initial implementation of the `camerapack` plugin.
- Support for capturing photos using native Android and iOS cameras.
- Support for flipping between front and back cameras.
- Gallery image picker support on Android.

### Fixed
- Updated plugin metadata (description, license, homepage).

---

## [0.0.1] - 2025-04-10
### Added
- Initial release of the `camerapack` plugin with basic camera functionality (Android and iOS).
