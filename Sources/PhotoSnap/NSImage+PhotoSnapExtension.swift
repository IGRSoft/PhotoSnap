//
//  NSImage+PhotoSnapExtension.swift
//  Example
//
//  Created by Vitalii Parovishnyk on 29.11.2020.
//

import AppKit

extension NSImage {
    func data(for type: PhotoSnapConfiguration.ImageType) -> Data? {
        let tiffData = self.tiffRepresentation
        
        var imageType = NSBitmapImageRep.FileType.png
        var imageProps = [NSBitmapImageRep.PropertyKey : Any]()
        
        switch type {
        
        case .png:
            imageType = .png
        case .tiff:
            imageType = .tiff
        case .jpeg:
            imageType = .jpeg
            imageProps = [
                NSBitmapImageRep.PropertyKey.compressionFactor: 0.9
            ]
        case .bmp:
            imageType = .bmp
        case .gif:
            imageType = .gif
        }
        
        let imageRep = NSBitmapImageRep(data: tiffData!)
        let photoData = imageRep?.representation(using: imageType, properties: imageProps)
        
        return photoData
    }
    
    @discardableResult
    func save(to path: URL, for type: PhotoSnapConfiguration.ImageType) -> Bool {
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
