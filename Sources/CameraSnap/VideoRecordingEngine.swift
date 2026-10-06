import AVFoundation
import CoreMedia
import Foundation

/// All mutable media state is confined to the camera's serial sample queue.
final class VideoRecordingEngine: @unchecked Sendable {
    enum Fault {
        case none, setup, append, finish, stallFinish
    }

    private enum State {
        case awaitingFirstFrame
        case writing(start: CMTime, last: CMTime)
        case finishing
        case terminal
    }

    private let queue: DispatchQueue
    private let duration: TimeInterval
    private let destination: URL
    private let staging: URL
    private let outputSize: CameraSnapConfiguration.OutputSize
    private let fault: Fault
    private let completion: @Sendable (Result<CameraSnapVideoModel, CameraSnapVideoError>) -> Void
    private var state: State = .awaitingFirstFrame
    private var writer: AVAssetWriter?
    private var input: AVAssetWriterInput?
    private var pending: [CMSampleBuffer] = []
    private var targetEnd: CMTime?
    private var drainScheduled = false

    init(queue: DispatchQueue, duration: TimeInterval, destination: URL,
         outputSize: CameraSnapConfiguration.OutputSize = .original,
         fault: Fault = .none,
         completion: @escaping @Sendable (Result<CameraSnapVideoModel, CameraSnapVideoError>) -> Void) {
        self.queue = queue
        self.duration = duration
        self.destination = destination
        self.outputSize = outputSize
        self.staging = destination.deletingLastPathComponent()
            .appendingPathComponent(".camerasnap-\(UUID().uuidString).mov")
        self.fault = fault
        self.completion = completion
    }

    func accept(_ sample: CMSampleBuffer) {
        dispatchPrecondition(condition: .onQueue(queue))
        guard targetEnd == nil else { return }
        if case .finishing = state { return }
        if case .terminal = state { return }
        append(sample)
    }

    private func append(_ sample: CMSampleBuffer) {
        let pts = CMSampleBufferGetPresentationTimeStamp(sample)
        guard pts.isValid, pts.isNumeric, let pixelBuffer = CMSampleBufferGetImageBuffer(sample) else {
            terminate(.writerFailed)
            return
        }
        switch state {
        case .awaitingFirstFrame:
            guard makeWriter(width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer), start: pts) else {
                terminate(.writerFailed)
                return
            }
            state = .writing(start: pts, last: pts)
        case .writing(let start, let last):
            guard CMTimeCompare(pts, last) > 0 else {
                terminate(.writerFailed)
                return
            }
            let end = CMTimeAdd(start, CMTime(seconds: duration, preferredTimescale: 60_000))
            if CMTimeCompare(pts, end) >= 0 {
                targetEnd = end
                drain()
                return
            }
            state = .writing(start: start, last: pts)
        case .finishing, .terminal:
            return
        }
        pending.append(sample)
        drain()
    }

    private func makeWriter(width: Int, height: Int, start: CMTime) -> Bool {
        guard fault != .setup, width > 0, height > 0 else { return false }
        let outputWidth = scaledVideoDimension(width)
        let outputHeight = scaledVideoDimension(height)
        guard let writer = try? AVAssetWriter(outputURL: staging, fileType: .mov) else {
            Logger.debug("Cannot initialize MOV writer at \(staging)")
            return false
        }
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: outputWidth,
            AVVideoHeightKey: outputHeight,
            AVVideoScalingModeKey: AVVideoScalingModeResizeAspect
        ])
        input.expectsMediaDataInRealTime = true
        guard writer.canAdd(input) else {
            Logger.debug("Cannot add H.264 input")
            return false
        }
        writer.add(input)
        guard writer.startWriting() else {
            Logger.debug("Cannot start MOV writer: \(String(describing: writer.error))")
            return false
        }
        writer.startSession(atSourceTime: start)
        self.writer = writer
        self.input = input
        return true
    }

    private func scaledVideoDimension(_ value: Int) -> Int {
        guard outputSize != .original else { return value }
        let scaled = max(2, value / outputSize.divisor)
        return scaled - (scaled % 2)
    }

    private func drain() {
        dispatchPrecondition(condition: .onQueue(queue))
        if case .finishing = state { return }
        if case .terminal = state { return }
        guard let input else { return }
        while input.isReadyForMoreMediaData, !pending.isEmpty {
            guard fault != .append, input.append(pending.removeFirst()) else {
                terminate(.writerFailed)
                return
            }
        }
        if !pending.isEmpty, !drainScheduled {
            drainScheduled = true
            queue.asyncAfter(deadline: .now() + .milliseconds(5)) { [self] in
                drainScheduled = false
                drain()
            }
        }
        if pending.isEmpty, let targetEnd {
            finish(at: targetEnd)
        }
    }

    private func finish(at end: CMTime) {
        guard case .writing = state, let writer, let input else { return }
        state = .finishing
        input.markAsFinished()
        writer.endSession(atSourceTime: end)
        queue.asyncAfter(deadline: .now() + .seconds(5)) { [weak self] in
            self?.finalizationDeadlineExpired()
        }
        if fault == .stallFinish {
            queue.async { [weak self] in
                guard let self else { return }
                self.finalizationDeadlineExpired()
                self.finishCompleted()
            }
            return
        }
        writer.finishWriting { [weak self] in
            guard let self else { return }
            self.queue.async { [weak self] in self?.finishCompleted() }
        }
    }

    func finalizationDeadlineExpired() {
        dispatchPrecondition(condition: .onQueue(queue))
        if case .finishing = state { terminate(.finalizationFailed) }
    }

    func finishCompleted() {
        dispatchPrecondition(condition: .onQueue(queue))
        guard case .finishing = state else { return }
        guard fault != .finish, writer?.status == .completed else {
            terminate(.finalizationFailed)
            return
        }
        verifyAndMove()
    }

    private func verifyAndMove() {
        let asset = AVURLAsset(url: staging)
        let measured = CMTimeGetSeconds(asset.duration)
        let tracks = asset.tracks(withMediaType: .video)
        let codec = tracks.first?.formatDescriptions.first
            .map { CMFormatDescriptionGetMediaSubType($0 as! CMFormatDescription) }
        guard measured.isFinite, abs(measured - duration) <= 0.25,
              tracks.count == 1, codec == kCMVideoCodecType_H264,
              asset.tracks(withMediaType: .audio).isEmpty else {
            terminate(.finalizationFailed)
            return
        }
        do {
            guard !FileManager.default.fileExists(atPath: destination.path) else {
                terminate(.destinationUnavailable)
                return
            }
            try FileManager.default.moveItem(at: staging, to: destination)
            state = .terminal
            completion(.success(CameraSnapVideoModel(url: destination, duration: measured)))
        } catch {
            terminate(.destinationUnavailable)
        }
    }

    func timeout() {
        dispatchPrecondition(condition: .onQueue(queue))
        switch state {
        case .awaitingFirstFrame, .writing: terminate(.captureTimedOut)
        case .finishing: terminate(.finalizationFailed)
        case .terminal: break
        }
    }

    func terminate(_ error: CameraSnapVideoError) {
        dispatchPrecondition(condition: .onQueue(queue))
        guard case .terminal = state else {
            Logger.debug("Video recording failed: \(error), writer status: \(String(describing: writer?.status)), writer error: \(String(describing: writer?.error))")
            state = .terminal
            pending.removeAll()
            writer?.cancelWriting()
            try? FileManager.default.removeItem(at: staging)
            completion(.failure(error))
            return
        }
    }
}

@MainActor
protocol VideoRecordingSource: AnyObject {
    func start(using bridge: VideoRecordingBridge) -> Bool
    func beginSamples(using bridge: VideoRecordingBridge)
    func stop()
}

/// The delegate and recording commands enter the engine through this queue-bound bridge.
final class VideoRecordingBridge: @unchecked Sendable {
    let queue: DispatchQueue
    private var engine: VideoRecordingEngine?
    private var accepting = false

    init(queue: DispatchQueue) { self.queue = queue }

    func install(_ engine: VideoRecordingEngine) {
        queue.async { [self] in
            self.engine = engine
            self.accepting = false
        }
    }

    func startAccepting() {
        queue.async { [self] in accepting = true }
    }

    func accept(_ sample: CMSampleBuffer) {
        dispatchPrecondition(condition: .onQueue(queue))
        if accepting { engine?.accept(sample) }
    }

    func timeout() {
        queue.async { [self] in engine?.timeout() }
    }

    func clear() {
        queue.async { [self] in
            accepting = false
            engine = nil
        }
    }
}

// MARK: - Test Info
// @test-file: Tests/CameraSnapTests/CameraSnapVideoWriterTests.swift
// @test-coverage: PTS-bound H.264 MOV, fault cleanup, and terminal callback
