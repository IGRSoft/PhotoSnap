# CameraSnap
Forked and improved from: https://github.com/samgreen/ImageSnapMavericks

A Lib lets you capture still images from an iSight or other video source.

## Requirements

- macOS 12+ for the CameraSnap package and Example app
- Xcode with Swift 6.3 or newer
- Swift 6.3+

# Installation
### Swift Package Manager

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code and is integrated into the `swift` compiler.

Once you have your Swift package set up, adding CameraSnap as a dependency is as easy as adding it to the `dependencies` value of your `Package.swift`.

```swift
dependencies: [
    .package(url: "https://github.com/IGRSoft/CameraSnap.git", .upToNextMajor(from: "0.3.0"))
]
```

### Manually

If you prefer not to use any of the aforementioned dependency managers, you can integrate CameraSnap into your project manually.

# Usage
See Example

### Silent video recording

`recordVideo` accepts a duration of 1-5 seconds, inclusive. Recordings are silent H.264 MOV files. The host app must include `NSCameraUsageDescription`, and the user must grant camera access; no microphone permission is needed.

```swift
import CameraSnap

let snap = CameraSnap()
snap.cameraSnapConfiguration.imageSize = .half
snap.cameraSnapConfiguration.videoSize = .quarter
snap.recordVideo(for: 3.0) { result in
    switch result {
    case .success(let video):
        print("Saved \(video.url) (\(video.duration) seconds)")
    case .failure(let error):
        switch error {
        case .invalidDuration:
            print("Choose a duration from 1 through 5 seconds")
        default:
            print("Recording failed: \(error)")
        }
    }
}
```

Still images and videos default to `.original`. Set `imageSize` or `videoSize` to `.half` or `.quarter` to encode output at 1/2 or 1/4 of the camera frame's width and height while preserving its aspect ratio.

The callback runs once on the main actor after the file is finalized or cleanup completes. `CameraSnapVideoModel.url` points to the completed recording and `duration` is measured from the media. You can pass `from:` to select a camera, `to:` for an exact `.mov` output location, and `withWarmup:` to change the one-second pre-recording warmup. An existing destination is preserved and reported as `.destinationUnavailable`. Without `to:`, CameraSnap creates a unique file under the configured `rootDir` using `filePrefix` and `dateFormatter`.

Only one recording can run at a time; another request fails with `.recordingInProgress`. Calling `fetchSnapshot` during a recording returns an empty `CameraSnapModel` without interrupting the video. Other `CameraSnapVideoError` cases distinguish invalid duration, unavailable camera, session setup, destination, writer, capture timeout, and finalization failures.

### Migrating from PhotoSnap 0.2

Version 0.3 renames the package product and module from `PhotoSnap` to `CameraSnap`. Replace `import PhotoSnap` with `import CameraSnap`, rename public `PhotoSnap*` types to `CameraSnap*`, and rename `photoSnapConfiguration` to `cameraSnapConfiguration`. The default output directory is now `~/CameraSnap`.

The macOS example in `Example/Example.xcodeproj` uses this checkout as a local Swift package. Open it from the repository so Xcode can resolve the adjacent `Package.swift`.

To verify the package and example locally:

```sh
swift build
swift test
xcodebuild -project Example/Example.xcodeproj -scheme Example -configuration Debug build
```

The CameraSnap package and Example project target macOS 12 or newer. Camera capture still requires a connected camera and permission; package tests use in-memory images instead.

# Image Formats
The following image formats are supported and are determined by the filename extension: JPEG, TIFF, PNG, GIF, BMP.

# License

CameraSnap is available under the MIT license. See the [LICENSE](LICENSE) file for more info.

# Changelog

See [CHANGELOG.md](CHANGELOG.md) for release history and unreleased changes.
