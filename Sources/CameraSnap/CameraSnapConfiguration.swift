//
//  CameraSnapConfiguration.swift
//  Example
//
//  Created by Vitalii Parovishnyk on 27.11.2020.
//

import Foundation

public struct CameraSnapConfiguration {
    public enum OutputSize: String, CaseIterable, Sendable {
        case original = "Original"
        case half = "1/2"
        case quarter = "1/4"

        var divisor: Int {
            switch self {
            case .original: return 1
            case .half: return 2
            case .quarter: return 4
            }
        }
    }

    public enum ImageType: String, CaseIterable {
        case png
        case tiff
        case jpeg
        case bmp
        case gif
    }

    public var isSaveToFile = false

    public var imageType: ImageType = .png

    public var imageSize: OutputSize = .original

    public var videoSize: OutputSize = .original

    public var dateFormatter = DateFormatter()

    public var rootDir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("CameraSnap")

    public var filePrefix = "snapshot_"

    public var filePathURL: URL {
        return rootDir.appendingPathComponent("\(filePrefix)\(dateFormatter.string(from: Date()))")
            .appendingPathExtension("\(imageType.rawValue)")
    }

    /// A unique `.mov` URL under `rootDir`, using `filePrefix` and `dateFormatter`.
    public var videoFilePathURL: URL {
        rootDir.appendingPathComponent("\(filePrefix)\(dateFormatter.string(from: Date()))_\(UUID().uuidString)")
            .appendingPathExtension("mov")
    }

    init() {
        dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX") as Locale
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss.SSS"
    }
}

// MARK: - Test Info
// @test-file: Tests/CameraSnapTests/CameraSnapConfigurationTest.swift
// @related-tests: Tests/CameraSnapTests/CameraSnapVideoWriterTests.swift
// @test-coverage: Defaults and generated paths for every image type
