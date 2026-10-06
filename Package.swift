// swift-tools-version:6.3

import PackageDescription

let package = Package(
    name: "CameraSnap",
    platforms: [.macOS(.v12)],
    products: [
        .library(name: "CameraSnap", targets: ["CameraSnap"])
    ],
    targets: [
        .target(
            name: "CameraSnap",
            linkerSettings: [
                .linkedFramework("AVFoundation", .when(platforms: [.macOS]))
            ]
        ),
        .testTarget(name: "CameraSnapTests", dependencies: ["CameraSnap"])
    ],
    swiftLanguageModes: [.v6]
)
