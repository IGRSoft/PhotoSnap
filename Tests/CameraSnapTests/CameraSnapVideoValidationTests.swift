import XCTest
@testable import CameraSnap

final class CameraSnapVideoValidationTests: XCTestCase {
    // @test-required
    @MainActor
    func testDurationBoundariesAcceptOneAndFive() {
        XCTAssertTrue((1.0...5.0).contains(1.0))
        XCTAssertTrue((1.0...5.0).contains(5.0))
        XCTAssertTrue(CameraSnap.isValidVideoDuration(1.0))
        XCTAssertTrue(CameraSnap.isValidVideoDuration(5.0))
    }

    // @test-required
    @MainActor
    func testInvalidDurationCompletesOnceBeforeDeviceOrFileWork() {
        let snap = CameraSnap()
        snap.defaultDevice = nil
        for duration in [0.99, 5.01, .nan, .infinity, -.infinity] {
            var calls = 0
            snap.recordVideo(for: duration) { result in
                calls += 1
                XCTAssertEqual(result, .failure(.invalidDuration))
            }
            XCTAssertEqual(calls, 1)
        }
    }

    // @test-required
    @MainActor
    func testMissingDeviceCompletesOnce() {
        let snap = CameraSnap()
        snap.defaultDevice = nil
        var calls = 0
        snap.recordVideo(for: 1) { result in
            calls += 1
            XCTAssertEqual(result, .failure(.deviceUnavailable))
        }
        XCTAssertEqual(calls, 1)
    }
}

// MARK: - Source Info
// @source-file: Sources/CameraSnap/CameraSnap.swift
// @related-source-files: Sources/CameraSnap/CameraSnapVideoError.swift
