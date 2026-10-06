//
//  CameraSnap.swift
//  CameraSnap
//
//  Created by Vitalii Parovishnyk on 26.11.2020.
//

import AppKit
import AVFoundation
import CoreVideo

class Logger {
    class func debug(_ msg: String) {
#if DEBUG
        print(msg)
#endif
    }
}

// The lock retains each frame while it crosses the delegate queue into the capture actor.
private final class LatestFrame: @unchecked Sendable {
    private let lock = NSLock()
    private var frame: CVImageBuffer?

    func store(_ frame: CVImageBuffer?) {
        lock.lock()
        self.frame = frame
        lock.unlock()
    }

    func load() -> CVImageBuffer? {
        lock.lock()
        defer { lock.unlock() }
        return frame
    }

    func clear() {
        store(nil)
    }
}

@MainActor
public class CameraSnap: NSObject {
    static func isValidVideoDuration(_ duration: TimeInterval) -> Bool {
        duration.isFinite && (1.0...5.0).contains(duration)
    }
    
    public var cameraSnapConfiguration = CameraSnapConfiguration()
    
    private nonisolated let recordingBridge = VideoRecordingBridge(
        queue: DispatchQueue(label: "com.igrsoft.VideoCaptureQueue"))
    private let latestFrame = LatestFrame()
    private var videoRequestID: UUID?
    private var videoCompletion: ((Result<CameraSnapVideoModel, CameraSnapVideoError>) -> Void)?
    var recordingSource: VideoRecordingSource?
    
    private let captureSession = AVCaptureSession()
    
    private var input: AVCaptureDeviceInput? = nil
    private var output: AVCaptureVideoDataOutput? = nil
    
    public lazy var session: AVCaptureDevice.DiscoverySession = {
        let session = AVCaptureDevice.DiscoverySession ( deviceTypes: [ .builtInWideAngleCamera, .externalUnknown ],
                                                         mediaType: .video,
                                                         position: .unspecified)
        return session
    }()
    
    public lazy var defaultDevice: AVCaptureDevice? = {
        return session.devices.first
    }()
    
    private func readCurrentFrame() -> NSImage? {
        Logger.debug("Taking snapshot...")
        var frame: CVImageBuffer? = nil // Hold frame we find
        while frame == nil {
            Logger.debug("\tEntering synchronized block to see if frame is captured yet...")
            frame = latestFrame.load()
            Logger.debug("Done.")
            
            if frame == nil {
                RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
            }
        }
        
        // Convert frame to an NSImage
        guard let frame else { return nil }
        let imageRep = NSCIImageRep(ciImage: CIImage(cvImageBuffer: frame))
        let snapshot = NSImage(size: imageRep.size)
        snapshot.addRepresentation(imageRep)
        
        Logger.debug("Snapshot taken.")
        
        return snapshot
    }
    
    public func fetchSnapshot(from captureDevice: AVCaptureDevice? = nil,
                              withWarmup warmup: Int = 1,
                              withTimelapse timelapse: Double = 0.0,
                              resultBlock: @escaping (CameraSnapModel) -> Void) {
        
        var model = CameraSnapModel()
        if videoRequestID != nil {
            resultBlock(model)
            return
        }
        
        let cameraDevice = captureDevice ?? self.defaultDevice
        
        guard let device = cameraDevice else {
            resultBlock(model)
            
            return
        }
        
        Logger.debug("Starting device...")
        if self.startSession(device) {
            Logger.debug("Device started.")
            
            if warmup > 0 {
                Logger.debug("Delaying \(warmup)) seconds for warmup...")
                RunLoop.current.run(until: Date().addingTimeInterval(TimeInterval(warmup)))
                Logger.debug("Warmup complete.")
            }
            
            if timelapse > 0.0 {
                Logger.debug("Time lapse: snapping every \(timelapse) seconds to current directory.")
                
                if cameraSnapConfiguration.isSaveToFile {
                    var isDir: ObjCBool = false
                    let fm = FileManager.default
                    if fm.fileExists(atPath: cameraSnapConfiguration.rootDir.path, isDirectory: &isDir), isDir.boolValue == false {
                        do {
                            try fm.createDirectory(at: cameraSnapConfiguration.rootDir, withIntermediateDirectories: false, attributes: nil)
                        } catch {
                            Logger.debug("Can't create a folder: \(cameraSnapConfiguration.rootDir)")
                        }
                    }
                }
                
                var seq = 0
                while true {
                    let now = Date()
                    
                    Logger.debug(" - Snapshot \(seq)")
                    Logger.debug(" (\(now))")
                    
                    let filePath = cameraSnapConfiguration.filePathURL
                    let updatedFilePath = URL(fileURLWithPath: filePath.deletingPathExtension().absoluteString + "_\(seq)").appendingPathExtension(filePath.pathExtension)
                    
                    // capture and write
                    if let capturedImage = self.readCurrentFrame() {
                        let image = capturedImage.resized(for: cameraSnapConfiguration.imageSize)
                        if cameraSnapConfiguration.isSaveToFile {
                            image.save(to: updatedFilePath, for: cameraSnapConfiguration.imageType)
                            model.paths.append(updatedFilePath)
                        }
                        model.images.append(image)
                    }
                    Logger.debug("\(updatedFilePath)")
                    
                    // sleep
                    RunLoop.current.run(until: now.addingTimeInterval(timelapse))
                    seq += 1
                }
            }
            else if let capturedImage = self.readCurrentFrame() {
                let image = capturedImage.resized(for: cameraSnapConfiguration.imageSize)
                let filePath = cameraSnapConfiguration.filePathURL
                if cameraSnapConfiguration.isSaveToFile {
                    image.save(to: filePath, for: cameraSnapConfiguration.imageType)
                    model.paths.append(filePath)
                }
                model.images.append(image)
            }
            
            self.stopSession()
        }
        
        resultBlock(model)
    }

    /// Records a silent H.264 MOV over an inclusive 1–5 second media interval.
    /// Completion runs once on the main actor after finalization or cleanup.
    /// - Parameters:
    ///   - duration: A finite recording interval from 1 through 5 seconds.
    ///   - captureDevice: The camera to use, or the default camera when `nil`.
    ///   - destinationURL: The exact unused `.mov` URL, or a generated configured URL when `nil`.
    ///   - warmup: Whole seconds to wait before accepting video samples.
    ///   - resultBlock: The finalized recording or a typed recording failure.
    public func recordVideo(for duration: TimeInterval,
                            from captureDevice: AVCaptureDevice? = nil,
                            to destinationURL: URL? = nil,
                            withWarmup warmup: Int = 1,
                            resultBlock: @escaping (Result<CameraSnapVideoModel, CameraSnapVideoError>) -> Void) {
        guard Self.isValidVideoDuration(duration) else {
            resultBlock(.failure(.invalidDuration))
            return
        }
        guard videoRequestID == nil else {
            resultBlock(.failure(.recordingInProgress))
            return
        }
        let device = recordingSource == nil ? (captureDevice ?? defaultDevice) : nil
        guard recordingSource != nil || device != nil else {
            resultBlock(.failure(.deviceUnavailable))
            return
        }
        let destination = destinationURL ?? cameraSnapConfiguration.videoFilePathURL
        let parent = destination.deletingLastPathComponent()
        guard destination.isFileURL, destination.pathExtension.lowercased() == "mov" else {
            resultBlock(.failure(.destinationUnavailable))
            return
        }
        do {
            if destinationURL == nil {
                try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
            }
            var isDirectory: ObjCBool = false
            guard !FileManager.default.fileExists(atPath: destination.path),
                  FileManager.default.fileExists(atPath: parent.path, isDirectory: &isDirectory),
                  isDirectory.boolValue else {
                resultBlock(.failure(.destinationUnavailable))
                return
            }
        } catch {
            resultBlock(.failure(.destinationUnavailable))
            return
        }

        let id = UUID()
        videoRequestID = id
        videoCompletion = resultBlock
        let engine = VideoRecordingEngine(queue: recordingBridge.queue,
                                          duration: duration,
                                          destination: destination,
                                          outputSize: cameraSnapConfiguration.videoSize) { [self] result in
            Task { @MainActor [self] in
                guard self.videoRequestID == id else { return }
                if let recordingSource = self.recordingSource {
                    recordingSource.stop()
                } else {
                    self.stopSession()
                }
                self.recordingBridge.clear()
                self.videoRequestID = nil
                let completion = self.videoCompletion
                self.videoCompletion = nil
                completion?(result)
            }
        }
        recordingBridge.install(engine)
        let started: Bool
        if let recordingSource {
            started = recordingSource.start(using: recordingBridge)
        } else if let device {
            started = startSession(device)
        } else {
            started = false
        }
        guard started else {
            recordingSource?.stop()
            recordingBridge.clear()
            videoRequestID = nil
            videoCompletion = nil
            resultBlock(.failure(.sessionSetupFailed))
            return
        }
        Task { @MainActor [weak self] in
            if warmup > 0 {
                let safeWarmup = min(warmup, Int(UInt64.max / 1_000_000_000))
                try? await Task.sleep(nanoseconds: UInt64(safeWarmup) * 1_000_000_000)
            }
            guard let self, self.videoRequestID == id else { return }
            self.recordingBridge.startAccepting()
            self.recordingSource?.beginSamples(using: self.recordingBridge)
            Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: UInt64((duration * 3 + 2) * 1_000_000_000))
                guard let self, self.videoRequestID == id else { return }
                self.recordingBridge.timeout()
            }
        }
    }
    
    private func stopSession() {
        Logger.debug("Stopping session...")
        
        // Make sure we've stopped
        while captureSession.isRunning {
            Logger.debug("\tCaptureSession != nil")
            
            Logger.debug("\tStopping CaptureSession...")
            captureSession.stopRunning()
            Logger.debug("Done.")
            
            if captureSession.isRunning {
                Logger.debug("[mCaptureSession isRunning]")
                RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
            }
        }

        output?.setSampleBufferDelegate(nil, queue: nil)
        for input in captureSession.inputs { captureSession.removeInput(input) }
        for output in captureSession.outputs { captureSession.removeOutput(output) }
        input = nil
        output = nil
        latestFrame.clear()
    }
    
    private func startSession(_ device: AVCaptureDevice) -> Bool {
        Logger.debug("\tStopping previous session.")
        stopSession()
        
        Logger.debug("Starting capture session...")
        
        // Create the capture session
        Logger.debug("\tCreating AVCaptureSession...")
        captureSession.sessionPreset = .high
        Logger.debug("Done.")
        
        Logger.debug("\tCreating AVCaptureDeviceInput with \(device.description)...");
        do {
            input = try AVCaptureDeviceInput(device: device)
        } catch {
            Logger.debug("Can't create capture input: \(error)")
            stopSession()
            return false
        }
        Logger.debug("Done.");
        guard let input, captureSession.canAddInput(input) else {
            Logger.debug("Can't add capture input")
            stopSession()
            return false
        }
        captureSession.addInput(input)
        
        // Decompressed video output
        Logger.debug("\tCreating AVCaptureDecompressedVideoOutput...");
        output = AVCaptureVideoDataOutput()
        output?.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA)
        ]
        
        // Add sample buffer serial queue
        output?.setSampleBufferDelegate(self, queue: recordingBridge.queue)
        Logger.debug("Done.");
        guard let output, captureSession.canAddOutput(output) else {
            Logger.debug("Can't add capture output")
            stopSession()
            return false
        }
        captureSession.addOutput(output)
        
        // Clear old image?
        Logger.debug("\tEntering synchronized block to clear memory...")
        
        latestFrame.clear()
        Logger.debug("Done.")
        
        captureSession.startRunning()
        Logger.debug("Session started.")
        
        return true
    }
}

extension CameraSnap: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Swap out old frame for new one
        let videoFrame = CMSampleBufferGetImageBuffer(sampleBuffer)
        
        latestFrame.store(videoFrame)
        recordingBridge.accept(sampleBuffer)
    }
}

// MARK: - Test Info
// @test-file: Tests/CameraSnapTests/CameraSnapTests.swift
// @related-tests: Tests/CameraSnapTests/CameraSnapVideoValidationTests.swift
// @test-coverage: Capture object configuration without camera hardware
