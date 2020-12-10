//
//  PhotoSnapConfigurationTest.swift
//  
//
//  Created by Vitalii Parovishnyk on 10.12.2020.
//

import XCTest
@testable import PhotoSnap

final class PhotoSnapConfigurationTest: XCTestCase {
    func testEnums() {
        var config = PhotoSnapConfiguration()
        
        for type in PhotoSnapConfiguration.ImageType.allCases {
            config.imageType = type
            switch type {
                case .png:
                    XCTAssertTrue(config.imageType == .png)
                case .tiff:
                    XCTAssertTrue(config.imageType == .tiff)
                case .jpeg:
                    XCTAssertTrue(config.imageType == .jpeg)
                case .bmp:
                    XCTAssertTrue(config.imageType == .bmp)
                case .gif:
                    XCTAssertTrue(config.imageType == .gif)
                }
        }
    }
    
    func testDefaultValues() {
        let config = PhotoSnapConfiguration()
        
        XCTAssertTrue(config.imageType == .png)
        XCTAssertFalse(config.isSaveToFile)
        XCTAssertNotNil(config.dateFormatter)
        XCTAssertTrue(config.rootDir.absoluteString.count > 0)
        XCTAssertTrue(config.filePrefix.count > 0)
        XCTAssertTrue(config.filePathURL.absoluteString.count > 0)
    }

    static var allTests = [
        ("testEnums", testEnums),
        ("testDefaultValues", testDefaultValues),
    ]
}
