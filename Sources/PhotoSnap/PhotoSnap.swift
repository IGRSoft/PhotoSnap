//
//  PhotoSnap.swift
//  PhotoSnap
//
//  Created by Vitalii Parovishnyk on 26.11.2020.
//

#if os(macOS)

import AppKit
import AVFoundation
import CoreVideo

class Logger {
    class func debug(_ msg: String) {
        //print(msg)
    }
}

class PhotoSnap: NSObject {
    
    var photoSnapConfiguration = PhotoSnapConfiguration()
    
    let lockQueue = DispatchQueue(label: "com.igrsoft.PhotoSnap")
    let videoCaptureQueue = DispatchQueue(label: "com.igrsoft.VideoCaptureQueue")
    
    let captureSession = AVCaptureSession()
    
    private var input: AVCaptureDeviceInput? = nil
    private var output: AVCaptureVideoDataOutput? = nil
    
    private var mCurrentImageBuffer: CVImageBuffer? = nil
    
    lazy var session: AVCaptureDevice.DiscoverySession = {
        let s = AVCaptureDevice.DiscoverySession (
            deviceTypes: [ .builtInWideAngleCamera, .externalUnknown ],
            mediaType: .video,
            position: .unspecified)
        return s
    }()
    
    lazy var defaultDevice: AVCaptureDevice? = {
        return session.devices.first
    }()
    
    private func readCurrentFrame() -> NSImage? {
        Logger.debug("Taking snapshot...")
        var frame: CVImageBuffer? = nil // Hold frame we find
        while frame == nil {
            Logger.debug("\tEntering synchronized block to see if frame is captured yet...")
            lockQueue.sync {
                frame = mCurrentImageBuffer // Hold current frame
            }
            Logger.debug("Done.")
            
            if frame == nil {
                RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
            }
        }
        
        // Convert frame to an NSImage
        let imageRep = NSCIImageRep(ciImage: CIImage(cvImageBuffer: frame!))
        let snapshot = NSImage(size: imageRep.size)
        snapshot.addRepresentation(imageRep)
        
        Logger.debug("Snapshot taken.")
        
        return snapshot
    }
    
    func fetchSnapshot(from d: AVCaptureDevice? = nil,
                       withWarmup warmup: Int = 0,
                       withTimelapse timelapse: Double = 0.0,
                       resultBlock: @escaping (PhotoSnapModel) -> Void) {
        
        var model = PhotoSnapModel()
        
        let device = d ?? self.defaultDevice!
        
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
                
                if photoSnapConfiguration.isSaveToFile {
                    var isDir: ObjCBool = false
                    let fm = FileManager.default
                    if fm.fileExists(atPath: photoSnapConfiguration.rootDir.path, isDirectory: &isDir), isDir.boolValue == false {
                        do {
                            try fm.createDirectory(at: photoSnapConfiguration.rootDir, withIntermediateDirectories: false, attributes: nil)
                        } catch {
                        }
                    }
                }
                
                var seq = 0
                while true {
                    let now = Date()
                    
                    Logger.debug(" - Snapshot \(seq)")
                    Logger.debug(" (\(now))")
                    
                    let filePath = photoSnapConfiguration.filePathURL
                    let updatedFilePath = URL(fileURLWithPath: filePath.deletingPathExtension().absoluteString + "_\(seq)").appendingPathExtension(filePath.pathExtension)
                    
                    // capture and write
                    if let image = self.readCurrentFrame() {
                        if photoSnapConfiguration.isSaveToFile {
                            image.save(to: updatedFilePath, for: photoSnapConfiguration.imageType)
                            model.pathes.append(updatedFilePath)
                        }
                        model.images.append(image)
                    }
                    Logger.debug("\(updatedFilePath)")
                    
                    // sleep
                    RunLoop.current.run(until: now.addingTimeInterval(timelapse))
                    seq += 1
                }
            }
            else if let image = self.readCurrentFrame() {
                let filePath = photoSnapConfiguration.filePathURL
                if photoSnapConfiguration.isSaveToFile {
                    image.save(to: filePath, for: photoSnapConfiguration.imageType)
                    model.pathes.append(filePath)
                }
                model.images.append(image)
            }
            
            self.stopSession()
        }
        
        resultBlock(model)
    }
    
    func stopSession() {
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
            } else {
                Logger.debug("\tShutting down 'stopSession(..)'")
                
                input = nil
                output = nil
            }
        }
    }
    
    func startSession(_ device: AVCaptureDevice) -> Bool {
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
        }
        Logger.debug("Done.");
        captureSession.addInput(input!)
        
        // Decompressed video output
        Logger.debug("\tCreating AVCaptureDecompressedVideoOutput...");
        output = AVCaptureVideoDataOutput()
        output?.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA)
        ]
        
        // Add sample buffer serial queue
        output?.setSampleBufferDelegate(self, queue: videoCaptureQueue)
        Logger.debug("Done.");
        captureSession.addOutput(output!)
        
        // Clear old image?
        Logger.debug("\tEntering synchronized block to clear memory...")
        
        lockQueue.sync {
            mCurrentImageBuffer = nil
        }
        Logger.debug("Done.")
        
        captureSession.startRunning()
        Logger.debug("Session started.")
        
        return true
    }
}

extension PhotoSnap: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Swap out old frame for new one
        let videoFrame = CMSampleBufferGetImageBuffer(sampleBuffer)
        
        lockQueue.sync {
            mCurrentImageBuffer = videoFrame
        }
    }
}

#endif
