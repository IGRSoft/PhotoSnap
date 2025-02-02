//
//  File.swift
//  
//
//  Created by Vitalii Parovishnyk on 10.12.2020.
//

import XCTest
@testable import PhotoSnap

final class PhotoSnapModelTest: XCTestCase {
    func testModel() {
        var model = PhotoSnapModel()
        let img = NSImage(named: NSImage.computerName)!
        let path = "path:///Users"
        
        model.images.append(img)
        XCTAssertEqual(model.images.count, 1)
        XCTAssertTrue(model.images.first != nil)
        model.images.append(img)
        XCTAssertEqual(model.images.count, 2)
        
        model.paths.append(URL(fileURLWithPath: path))
        XCTAssertEqual(model.paths.count, 1)
        XCTAssertTrue(model.paths.first != nil)
    }

    static var allTests = [
        ("testModel", testModel),
    ]
}
