import XCTest
import AppKit
@testable import PhotoSnap

final class PhotoSnapTests: XCTestCase {
    // @depends-on: PhotoSnap
    @MainActor
    func testCaptureConfigurationWithoutCamera() {
        let snap = PhotoSnap()
        snap.photoSnapConfiguration.imageType = .jpeg
        snap.photoSnapConfiguration.isSaveToFile = true

        XCTAssertEqual(snap.photoSnapConfiguration.imageType, .jpeg)
        XCTAssertTrue(snap.photoSnapConfiguration.isSaveToFile)
    }

    // @depends-on: PhotoSnap
    @MainActor
    func testNoDeviceStillCallsBack() {
        let snap = PhotoSnap()
        snap.defaultDevice = nil
        var result: PhotoSnapModel?

        snap.fetchSnapshot(withWarmup: 0) { result = $0 }

        XCTAssertNotNil(result)
        XCTAssertTrue(result?.images.isEmpty == true)
        XCTAssertTrue(result?.paths.isEmpty == true)
    }

    // @depends-on: NSImage
    @MainActor
    func testEverySupportedEncodingAndSaveResult() throws {
        let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 2, pixelsHigh: 2,
                                      bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                      isPlanar: false, colorSpaceName: .deviceRGB,
                                      bytesPerRow: 0, bitsPerPixel: 0)!
        bitmap.setColor(.red, atX: 0, y: 0)
        let image = NSImage(size: NSSize(width: 2, height: 2))
        image.addRepresentation(bitmap)

        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)
        defer { try? FileManager.default.removeItem(at: directory) }

        for type in PhotoSnapConfiguration.ImageType.allCases {
            let data = try XCTUnwrap(image.data(for: type))
            XCTAssertFalse(data.isEmpty)
            XCTAssertNotNil(NSBitmapImageRep(data: data))

            let destination = directory.appendingPathComponent("snapshot.\(type.rawValue)")
            XCTAssertTrue(image.save(to: destination, for: type))
            XCTAssertEqual(try Data(contentsOf: destination), data)
        }

        let missingParent = directory.appendingPathComponent("missing/snapshot.png")
        XCTAssertFalse(image.save(to: missingParent, for: .png))
    }
}

// MARK: - Source Info
// @source-file: Sources/PhotoSnap/PhotoSnap.swift
// @doc-refs: README.md
