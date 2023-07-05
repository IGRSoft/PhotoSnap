// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

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
    swiftLanguageVersions: [.v5]
)
