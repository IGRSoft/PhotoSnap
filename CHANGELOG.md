# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.0] - 2026-10-06

### Added

- Silent H.264 MOV recording with a configurable duration from 1 through 5 seconds.
- Original, half, and quarter output sizes for still images and videos.
- Typed video recording results and errors, unique output paths, staging-file cleanup, and recording overlap protection.
- Image and Video tabs in the Example app, with compact image and last-recorded-video previews.
- Automated coverage for image scaling, recording validation, output dimensions, media integrity, failure cleanup, and callback behavior.

### Changed

- **Breaking:** Renamed the package, library product, module, and public `PhotoSnap` types to `CameraSnap`.
- **Breaking:** Renamed `photoSnapConfiguration` to `cameraSnapConfiguration` and changed the default output directory from `~/PhotoSnap` to `~/CameraSnap`.
- Raised the minimum supported operating system to macOS 12 for the package and Example app.
- Modernized the package for Swift 6 strict concurrency and Swift tools 6.3.

## [0.2.2] - 2023-07-05

### Changed

- Updated Swift package and Example project settings.
- Set the default camera warmup interval to one second.

## [0.2.1] - 2021-07-25

### Fixed

- Corrected Example project package resolution and integration.

### Changed

- Applied source and package configuration cleanup.

## [0.2.0] - 2020-12-10

### Added

- Added Swift Package Manager support.
- Added package tests and an updated Example app.

### Changed

- Exposed the capture API and model types for package consumers.

## [0.1.0] - 2020-11-29

### Added

- Initial Swift implementation for capturing still images from a macOS camera.

[Unreleased]: https://github.com/IGRSoft/CameraSnap/compare/0.3.0...HEAD
[0.3.0]: https://github.com/IGRSoft/CameraSnap/compare/0.2.2...0.3.0
[0.2.2]: https://github.com/IGRSoft/CameraSnap/compare/0.2.1...0.2.2
[0.2.1]: https://github.com/IGRSoft/CameraSnap/compare/0.2.0...0.2.1
[0.2.0]: https://github.com/IGRSoft/CameraSnap/compare/0.1.0...0.2.0
[0.1.0]: https://github.com/IGRSoft/CameraSnap/releases/tag/0.1.0
