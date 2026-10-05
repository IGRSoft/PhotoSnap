//
//  File.swift
//  
//
//  Created by Vitalii Parovishnyk on 10.12.2020.
//

import XCTest
import AppKit
@testable import PhotoSnap

final class PhotoSnapModelTest: XCTestCase {
    // @depends-on: PhotoSnapModel
    @MainActor
    func testModel() {
        var model = PhotoSnapModel()
        let img = NSImage(size: NSSize(width: 2, height: 2))
        let path = URL(fileURLWithPath: "/tmp/snapshot.png")

        model.images.append(img)
        XCTAssertEqual(model.images.count, 1)
        XCTAssertTrue(model.images[0] === img)
        model.images.append(img)
        XCTAssertEqual(model.images.count, 2)

        model.paths.append(path)
        XCTAssertEqual(model.paths.count, 1)
        XCTAssertEqual(model.paths[0], path)
    }
}

// MARK: - Source Info
// @source-file: Sources/PhotoSnap/PhotoSnapModel.swift
