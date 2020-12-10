//
//  PhotoSnapConfiguration.swift
//  Example
//
//  Created by Vitalii Parovishnyk on 27.11.2020.
//

import Foundation

public struct PhotoSnapConfiguration {
    
    public enum ImageType: String, CaseIterable {
        case png
        case tiff
        case jpeg
        case bmp
        case gif
    }
    
    public var isSaveToFile = false
    
    public var imageType: ImageType = .png
    
    public var dateFormatter = DateFormatter()
    
    public var rootDir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("PhotoSnap")
    
    public var filePrefix = "snapshot_"
    
    public var filePathURL: URL {
        return rootDir.appendingPathComponent("\(filePrefix)\(dateFormatter.string(from: Date()))")
            .appendingPathExtension("\(imageType.rawValue)")
    }
    
    init() {
        dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX") as Locale
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss.SSS"
    }
}
