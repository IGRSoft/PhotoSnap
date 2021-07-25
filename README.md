# Capture Images from camera
Forked and improved from: https://github.com/samgreen/ImageSnapMavericks

A Lib lets you capture still images from an iSight or other video source.

## Requirements

- macOS 11.0+
- Xcode 11.4+
- Swift 5.1+

# Installation
### Swift Package Manager

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code and is integrated into the `swift` compiler.

Once you have your Swift package set up, adding PhotoSnap as a dependency is as easy as adding it to the `dependencies` value of your `Package.swift`.

```swift
dependencies: [
    .package(url: "https://github.com/iKorich/PhotoSnap.git", .upToNextMajor(from: "1.0.0"))
]
```

### Manually

If you prefer not to use any of the aforementioned dependency managers, you can integrate PhotoSnap into your project manually.

# Usage
See Example

# Image Formats
The following image formats are supported and are determined by the filename extension: JPEG, TIFF, PNG, GIF, BMP.

# License

PhotoSnap is available under the MIT license. See the [LICENSE](LICENSE) file for more info.

# Changes
=============
 * v0.1 - This is the initial release.
 
