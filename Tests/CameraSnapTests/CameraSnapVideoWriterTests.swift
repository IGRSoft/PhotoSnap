import AVFoundation
import CoreVideo
import XCTest
@testable import CameraSnap

final class CameraSnapVideoWriterTests: XCTestCase {
    // @test-required
    func testDefaultVideoPathIsUniqueAndConfigured() throws {
        var config = CameraSnapConfiguration()
        config.rootDir = URL(fileURLWithPath: "/tmp/camerasnap-unit", isDirectory: true)
        config.filePrefix = "clip_"
        config.dateFormatter.dateFormat = "'fixed'"
        let first = config.videoFilePathURL
        let second = config.videoFilePathURL
        XCTAssertNotEqual(first, second)
        XCTAssertEqual(first.deletingLastPathComponent(), config.rootDir)
        XCTAssertTrue(first.lastPathComponent.hasPrefix("clip_fixed_"))
        XCTAssertEqual(first.pathExtension, "mov")
    }

    // @test-required
    func testGeneratedBuffersProduceReadableSilentH264MOVAtOneAndFiveSeconds() async throws {
        for duration in [1.0, 5.0] {
            let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)
            defer { try? FileManager.default.removeItem(at: directory) }
            let url = directory.appendingPathComponent("explicit.mov")
            let result = await runEngine(duration: duration, destination: url)
            let model = try result.get()
            XCTAssertEqual(model.url, url)
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
            XCTAssertEqual(url.pathExtension, "mov")
            XCTAssertEqual(model.duration, duration, accuracy: 0.25)
            let asset = AVURLAsset(url: url)
            XCTAssertEqual(asset.tracks(withMediaType: .video).count, 1)
            XCTAssertTrue(asset.tracks(withMediaType: .audio).isEmpty)
            XCTAssertEqual(CMTimeGetSeconds(asset.duration), model.duration, accuracy: 0.001)
            let format = try XCTUnwrap(asset.tracks(withMediaType: .video).first?.formatDescriptions.first)
            XCTAssertEqual(CMFormatDescriptionGetMediaSubType(format as! CMFormatDescription), kCMVideoCodecType_H264)
        }
    }

    // @test-required
    func testVideoOutputSizesScaleEncodedDimensions() async throws {
        for (size, expected) in [(CameraSnapConfiguration.OutputSize.original, CGSize(width: 64, height: 64)),
                                 (.half, CGSize(width: 32, height: 32)),
                                 (.quarter, CGSize(width: 16, height: 16))] {
            let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)
            defer { try? FileManager.default.removeItem(at: directory) }
            let url = directory.appendingPathComponent("scaled.mov")
            let model = try await runEngine(duration: 1, destination: url, outputSize: size).get()
            let track = try XCTUnwrap(AVURLAsset(url: model.url).tracks(withMediaType: .video).first)
            XCTAssertEqual(track.naturalSize.width, expected.width)
            XCTAssertEqual(track.naturalSize.height, expected.height)
        }
    }

    // @test-required
    func testAppendAndFinalizationFailuresCleanStagingAndCompleteOnce() async throws {
        for fault in [VideoRecordingEngine.Fault.setup, .append, .finish] {
            let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)
            defer { try? FileManager.default.removeItem(at: directory) }
            let url = directory.appendingPathComponent("explicit.mov")
            let result = await runEngine(duration: 1, destination: url, fault: fault)
            XCTAssertTrue(result == .failure(fault == .finish ? .finalizationFailed : .writerFailed))
            XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
            XCTAssertTrue(try FileManager.default.contentsOfDirectory(atPath: directory.path).isEmpty)
        }
    }

    // @test-required
    func testExistingDestinationIsPreserved() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("existing.mov")
        let original = Data("keep".utf8)
        try original.write(to: url)
        let result = await runEngine(duration: 1, destination: url)
        XCTAssertEqual(result, .failure(.destinationUnavailable))
        XCTAssertEqual(try Data(contentsOf: url), original)
    }

    // @test-required
    func testNoFrameTimeoutCompletesOnceWithoutOutput() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)
        defer { try? FileManager.default.removeItem(at: directory) }
        let destination = directory.appendingPathComponent("timeout.mov")
        let result: Result<CameraSnapVideoModel, CameraSnapVideoError> = await withCheckedContinuation { continuation in
            let queue = DispatchQueue(label: "CameraSnapVideoWriterTests.timeout")
            let engine = VideoRecordingEngine(queue: queue, duration: 1, destination: destination) {
                continuation.resume(returning: $0)
            }
            queue.async {
                engine.timeout()
                engine.timeout()
            }
        }
        XCTAssertEqual(result, .failure(.captureTimedOut))
        XCTAssertTrue(try FileManager.default.contentsOfDirectory(atPath: directory.path).isEmpty)
    }

    // @test-required
    func testStalledFinalizationDeadlineCleansStagingAndIgnoresLateCallback() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)
        defer { try? FileManager.default.removeItem(at: directory) }
        let destination = directory.appendingPathComponent("stalled.mov")
        let result = await runEngine(duration: 1, destination: destination, fault: .stallFinish)
        XCTAssertEqual(result, .failure(.finalizationFailed))
        XCTAssertFalse(FileManager.default.fileExists(atPath: destination.path))
        XCTAssertTrue(try FileManager.default.contentsOfDirectory(atPath: directory.path).isEmpty)
    }

    private func runEngine(duration: TimeInterval, destination: URL,
                           outputSize: CameraSnapConfiguration.OutputSize = .original,
                           fault: VideoRecordingEngine.Fault = .none) async -> Result<CameraSnapVideoModel, CameraSnapVideoError> {
        await withCheckedContinuation { continuation in
            let queue = DispatchQueue(label: "CameraSnapVideoWriterTests.queue")
            let holder = VideoEngineHolder()
            let engine = VideoRecordingEngine(queue: queue, duration: duration, destination: destination,
                                              outputSize: outputSize, fault: fault) {
                holder.engine = nil
                continuation.resume(returning: $0)
            }
            holder.engine = engine
            queue.async {
                for index in 0...Int(duration * 30) {
                    guard let sample = Self.makeSample(at: index) else {
                        engine.terminate(.writerFailed)
                        return
                    }
                    engine.accept(sample)
                }
            }
        }
    }

    static func makeSample(at frameIndex: Int) -> CMSampleBuffer? {
        var pixel: CVPixelBuffer?
        let attributes: [String: Any] = [kCVPixelBufferCGImageCompatibilityKey as String: true,
                                         kCVPixelBufferCGBitmapContextCompatibilityKey as String: true]
        guard CVPixelBufferCreate(kCFAllocatorDefault, 64, 64, kCVPixelFormatType_32BGRA,
                                  attributes as CFDictionary, &pixel) == kCVReturnSuccess,
              let pixel else { return nil }
        CVPixelBufferLockBaseAddress(pixel, [])
        if let base = CVPixelBufferGetBaseAddress(pixel) {
            memset(base, 0, CVPixelBufferGetDataSize(pixel))
        }
        CVPixelBufferUnlockBaseAddress(pixel, [])
        var format: CMVideoFormatDescription?
        guard CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                                            imageBuffer: pixel, formatDescriptionOut: &format) == noErr,
              let format else { return nil }
        var timing = CMSampleTimingInfo(duration: CMTime(value: 1, timescale: 30),
                                        presentationTimeStamp: CMTime(value: Int64(frameIndex), timescale: 30),
                                        decodeTimeStamp: .invalid)
        var sample: CMSampleBuffer?
        guard CMSampleBufferCreateReadyWithImageBuffer(allocator: kCFAllocatorDefault,
                                                       imageBuffer: pixel, formatDescription: format,
                                                       sampleTiming: &timing, sampleBufferOut: &sample) == noErr else { return nil }
        return sample
    }
}

private final class VideoEngineHolder: @unchecked Sendable {
    var engine: VideoRecordingEngine?
}

// MARK: - Source Info
// @source-file: Sources/CameraSnap/VideoRecordingEngine.swift
// @related-source-files: Sources/CameraSnap/CameraSnapConfiguration.swift
