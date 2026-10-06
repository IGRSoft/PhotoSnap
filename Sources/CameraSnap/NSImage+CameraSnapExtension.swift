//
//  NSImage+CameraSnapExtension.swift
//  Example
//
//  Created by Vitalii Parovishnyk on 29.11.2020.
//

import AppKit

extension NSImage {
    func resized(for outputSize: CameraSnapConfiguration.OutputSize) -> NSImage {
        guard outputSize != .original,
              let source = cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return self
        }

        let width = max(1, source.width / outputSize.divisor)
        let height = max(1, source.height / outputSize.divisor)
        guard let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil,
                                            pixelsWide: width,
                                            pixelsHigh: height,
                                            bitsPerSample: 8,
                                            samplesPerPixel: 4,
                                            hasAlpha: true,
                                            isPlanar: false,
                                            colorSpaceName: .deviceRGB,
                                            bytesPerRow: 0,
                                            bitsPerPixel: 0),
              let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
            return self
        }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        context.imageInterpolation = .high
        context.cgContext.draw(source, in: CGRect(x: 0, y: 0, width: width, height: height))
        context.flushGraphics()
        NSGraphicsContext.restoreGraphicsState()

        let result = NSImage(size: NSSize(width: width, height: height))
        result.addRepresentation(bitmap)
        return result
    }

    func data(for type: CameraSnapConfiguration.ImageType) -> Data? {
        guard let tiffData = self.tiffRepresentation else { return nil }

        var imageType = NSBitmapImageRep.FileType.png
        var imageProps = [NSBitmapImageRep.PropertyKey : Any]()

        switch type {

        case .png:
            imageType = .png
        case .tiff:
            imageType = .tiff
        case .jpeg:
            imageType = .jpeg
            imageProps = [NSBitmapImageRep.PropertyKey.compressionFactor: 0.9]
        case .bmp:
            imageType = .bmp
        case .gif:
            imageType = .gif
        }

        let imageRep = NSBitmapImageRep(data: tiffData)
        let photoData = imageRep?.representation(using: imageType, properties: imageProps)

        return photoData
    }

    @discardableResult
    func save(to path: URL, for type: CameraSnapConfiguration.ImageType) -> Bool {
        var result = false

        if let photoData = self.data(for: type) {
            do {
                try photoData.write(to: path)
                print(path)
                result = true
            }
            catch {
                print(error)
                result = false
            }
        }

        return result
    }
}

// MARK: - Test Info
// @test-file: Tests/CameraSnapTests/CameraSnapTests.swift
// @test-coverage: Bitmap encoding and file save outcomes for every supported format
