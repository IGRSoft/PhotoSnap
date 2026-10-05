// swift-tools-version:6.3

import PackageDescription

let package = Package(
    name: "PhotoSnap",
    platforms: [.macOS(.v11)],
    products: [
        .library(name: "PhotoSnap", targets: ["PhotoSnap"])
    ],
    targets: [
        .target(
            name: "PhotoSnap",
            linkerSettings: [
                .linkedFramework("AVFoundation", .when(platforms: [.macOS]))
            ]
        ),
        .testTarget(name: "PhotoSnapTests", dependencies: ["PhotoSnap"])
    ],
    swiftLanguageModes: [.v6]
)
