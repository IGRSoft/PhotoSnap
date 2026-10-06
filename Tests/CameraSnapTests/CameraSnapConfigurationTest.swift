//
//  CameraSnapConfigurationTest.swift
//
//
//  Created by Vitalii Parovishnyk on 10.12.2020.
//

import XCTest
@testable import CameraSnap

final class CameraSnapConfigurationTest: XCTestCase {
    // @depends-on: CameraSnapConfiguration
    func testEnums() {
        XCTAssertEqual(CameraSnapConfiguration.ImageType.allCases.map(\.rawValue),
                       ["png", "tiff", "jpeg", "bmp", "gif"])
        XCTAssertEqual(CameraSnapConfiguration.OutputSize.allCases.map(\.rawValue),
                       ["Original", "1/2", "1/4"])
    }

    // @test-required
    func testDefaultValues() {
        let config = CameraSnapConfiguration()

        XCTAssertEqual(config.imageType, .png)
        XCTAssertEqual(config.imageSize, .original)
        XCTAssertEqual(config.videoSize, .original)
        XCTAssertFalse(config.isSaveToFile)
        XCTAssertEqual(config.filePrefix, "snapshot_")
        XCTAssertEqual(config.dateFormatter.dateFormat, "yyyy-MM-dd_HH-mm-ss.SSS")
        XCTAssertEqual(config.rootDir.lastPathComponent, "CameraSnap")
    }

    // @depends-on: CameraSnapConfiguration
    func testGeneratedPathsForEveryImageType() {
        var config = CameraSnapConfiguration()
        config.rootDir = URL(fileURLWithPath: "/tmp/camerasnap-tests", isDirectory: true)
        config.filePrefix = "test_"
        config.dateFormatter.dateFormat = "'fixed'"

        for type in CameraSnapConfiguration.ImageType.allCases {
            config.imageType = type
            XCTAssertEqual(config.filePathURL,
                           config.rootDir.appendingPathComponent("test_fixed.\(type.rawValue)"))
        }
    }
}

// MARK: - Source Info
// @source-file: Sources/CameraSnap/CameraSnapConfiguration.swift
