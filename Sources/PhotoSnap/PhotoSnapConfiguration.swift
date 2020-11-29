//
//  PhotoSnapConfiguration.swift
//  Example
//
//  Created by Vitalii Parovishnyk on 27.11.2020.
//

import Foundation

struct PhotoSnapConfiguration {
    
    enum ImageType: String {
        case png
        case tiff
        case jpeg
        case bmp
        case gif
    }
    
    var isSaveToFile = false
    
    var imageType: ImageType = .png
    
    var dateFormatter = DateFormatter()
    
    var rootDir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("PhotoSnap")
    
    var filePrefix = "snapshot_"
    
    var filePathURL: URL {
        return rootDir.appendingPathComponent("\(filePrefix)\(dateFormatter.string(from: Date()))")
            .appendingPathExtension("\(imageType.rawValue)")
    }
    
    init() {
        dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX") as Locale
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss.SSS"
    }
    
}
