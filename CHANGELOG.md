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
