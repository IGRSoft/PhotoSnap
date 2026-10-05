//
//  PhotoSnapConfigurationTest.swift
//  
//
//  Created by Vitalii Parovishnyk on 10.12.2020.
//

import XCTest
@testable import PhotoSnap

final class PhotoSnapConfigurationTest: XCTestCase {
    // @depends-on: PhotoSnapConfiguration
    func testEnums() {
        XCTAssertEqual(PhotoSnapConfiguration.ImageType.allCases.map(\.rawValue),
                       ["png", "tiff", "jpeg", "bmp", "gif"])
    }

    // @test-required
    func testDefaultValues() {
        let config = PhotoSnapConfiguration()

        XCTAssertEqual(config.imageType, .png)
        XCTAssertFalse(config.isSaveToFile)
        XCTAssertEqual(config.filePrefix, "snapshot_")
        XCTAssertEqual(config.dateFormatter.dateFormat, "yyyy-MM-dd_HH-mm-ss.SSS")
        XCTAssertEqual(config.rootDir.lastPathComponent, "PhotoSnap")
    }

    // @depends-on: PhotoSnapConfiguration
    func testGeneratedPathsForEveryImageType() {
        var config = PhotoSnapConfiguration()
        config.rootDir = URL(fileURLWithPath: "/tmp/photosnap-tests", isDirectory: true)
        config.filePrefix = "test_"
        config.dateFormatter.dateFormat = "'fixed'"

        for type in PhotoSnapConfiguration.ImageType.allCases {
            config.imageType = type
            XCTAssertEqual(config.filePathURL,
                           config.rootDir.appendingPathComponent("test_fixed.\(type.rawValue)"))
        }
    }
}

// MARK: - Source Info
// @source-file: Sources/PhotoSnap/PhotoSnapConfiguration.swift
