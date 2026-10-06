import XCTest
import AppKit
@testable import CameraSnap

final class CameraSnapTests: XCTestCase {
    // @depends-on: CameraSnap
    @MainActor
    func testCaptureConfigurationWithoutCamera() {
        let snap = CameraSnap()
        snap.cameraSnapConfiguration.imageType = .jpeg
        snap.cameraSnapConfiguration.isSaveToFile = true

        XCTAssertEqual(snap.cameraSnapConfiguration.imageType, .jpeg)
        XCTAssertTrue(snap.cameraSnapConfiguration.isSaveToFile)
    }

    // @depends-on: CameraSnap
    @MainActor
    func testNoDeviceStillCallsBack() {
        let snap = CameraSnap()
        snap.defaultDevice = nil
        var result: CameraSnapModel?

        snap.fetchSnapshot(withWarmup: 0) { result = $0 }

        XCTAssertNotNil(result)
        XCTAssertTrue(result?.images.isEmpty == true)
        XCTAssertTrue(result?.paths.isEmpty == true)
    }

    // @depends-on: CameraSnap
    @MainActor
    func testVideoNoDeviceLeavesSnapshotBehaviorIntact() {
        let snap = CameraSnap()
        snap.defaultDevice = nil
        var videoCalls = 0
        snap.recordVideo(for: 1) { result in
            videoCalls += 1
            XCTAssertEqual(result, .failure(.deviceUnavailable))
        }
        var snapshot: CameraSnapModel?
        snap.fetchSnapshot(withWarmup: 0) { snapshot = $0 }
        XCTAssertEqual(videoCalls, 1)
        XCTAssertNotNil(snapshot)
        XCTAssertTrue(snapshot?.images.isEmpty == true)
    }

    // @depends-on: CameraSnap
    @MainActor
    func testVideoSourceStartFailureCompletesOnceAndStopsSource() throws {
        let snap = CameraSnap()
        let source = ControllableVideoSource(startsSuccessfully: false)
        snap.recordingSource = source
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)
        defer { try? FileManager.default.removeItem(at: directory) }
        var calls = 0

        snap.recordVideo(for: 1, to: directory.appendingPathComponent("start-failure.mov"), withWarmup: 0) { result in
            calls += 1
            XCTAssertEqual(result, .failure(.sessionSetupFailed))
        }

        XCTAssertEqual(calls, 1)
        XCTAssertEqual(source.stopCount, 1)
    }

    // @depends-on: CameraSnap
    @MainActor
    func testOverlappingVideoRequestFailsOnceWithoutReplacingActiveRequest() async throws {
        let snap = CameraSnap()
        let source = ControllableVideoSource(startsSuccessfully: true)
        snap.recordingSource = source
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)
        defer { try? FileManager.default.removeItem(at: directory) }
        let firstFinished = expectation(description: "active recording completes")
        var firstResult: Result<CameraSnapVideoModel, CameraSnapVideoError>?
        var overlappingCalls = 0

        snap.recordVideo(for: 1, to: directory.appendingPathComponent("active.mov"), withWarmup: 0) { result in
            firstResult = result
            firstFinished.fulfill()
        }
        snap.recordVideo(for: 1, to: directory.appendingPathComponent("overlap.mov"), withWarmup: 0) { result in
            overlappingCalls += 1
            XCTAssertEqual(result, .failure(.recordingInProgress))
        }

        XCTAssertEqual(overlappingCalls, 1)
        source.bridge?.timeout()
        await fulfillment(of: [firstFinished], timeout: 1)
        XCTAssertEqual(firstResult, .failure(.captureTimedOut))
        XCTAssertEqual(source.stopCount, 1)
    }

    // @test-required
    @MainActor
    func testVideoCallbackSurvivesCallerReleaseAndReleasesOwnerAfterward() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)
        defer { try? FileManager.default.removeItem(at: directory) }
        let destination = directory.appendingPathComponent("lifetime.mov")
        let source = SyntheticVideoSource()
        let finished = expectation(description: "recording completes after caller releases CameraSnap")
        weak var weakSnap: CameraSnap?
        var received: Result<CameraSnapVideoModel, CameraSnapVideoError>?
        do {
            let snap = CameraSnap()
            snap.recordingSource = source
            weakSnap = snap
            snap.recordVideo(for: 1, to: destination, withWarmup: 0) { result in
                XCTAssertNotNil(weakSnap)
                received = result
                finished.fulfill()
            }
        }
        XCTAssertNotNil(weakSnap)
        await fulfillment(of: [finished], timeout: 5)
        XCTAssertEqual(try received?.get().url, destination)
        XCTAssertEqual(source.stopCount, 1)
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            source.bridge!.queue.async { continuation.resume() }
        }
        XCTAssertNil(weakSnap)
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

        for type in CameraSnapConfiguration.ImageType.allCases {
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

    // @test-required
    @MainActor
    func testImageOutputSizesScalePixelDimensions() throws {
        let bitmap = try XCTUnwrap(NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 80, pixelsHigh: 48,
                                                    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                                    isPlanar: false, colorSpaceName: .deviceRGB,
                                                    bytesPerRow: 0, bitsPerPixel: 0))
        let image = NSImage(size: NSSize(width: 80, height: 48))
        image.addRepresentation(bitmap)

        for (size, expected) in [(CameraSnapConfiguration.OutputSize.original, (80, 48)),
                                 (.half, (40, 24)),
                                 (.quarter, (20, 12))] {
            let data = try XCTUnwrap(image.resized(for: size).data(for: .png))
            let output = try XCTUnwrap(NSBitmapImageRep(data: data))
            XCTAssertEqual(output.pixelsWide, expected.0)
            XCTAssertEqual(output.pixelsHigh, expected.1)
        }
    }
}

@MainActor
private final class SyntheticVideoSource: VideoRecordingSource {
    var bridge: VideoRecordingBridge?
    var stopCount = 0

    func start(using bridge: VideoRecordingBridge) -> Bool {
        self.bridge = bridge
        return true
    }

    func beginSamples(using bridge: VideoRecordingBridge) {
        bridge.queue.async {
            for frame in 0...30 {
                if let sample = CameraSnapVideoWriterTests.makeSample(at: frame) {
                    bridge.accept(sample)
                }
            }
        }
    }

    func stop() { stopCount += 1 }
}

@MainActor
private final class ControllableVideoSource: VideoRecordingSource {
    let startsSuccessfully: Bool
    var bridge: VideoRecordingBridge?
    var stopCount = 0

    init(startsSuccessfully: Bool) {
        self.startsSuccessfully = startsSuccessfully
    }

    func start(using bridge: VideoRecordingBridge) -> Bool {
        self.bridge = bridge
        return startsSuccessfully
    }

    func beginSamples(using bridge: VideoRecordingBridge) {}

    func stop() { stopCount += 1 }
}

// MARK: - Source Info
// @source-file: Sources/CameraSnap/CameraSnap.swift
// @doc-refs: README.md
