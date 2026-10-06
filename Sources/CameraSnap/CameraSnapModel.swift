//
//  CameraSnapModel.swift
//  Example
//
//  Created by Vitalii Parovishnyk on 27.11.2020.
//

import AppKit
import Foundation

public struct CameraSnapModel {
    public var images = [NSImage]()
    public var paths = [URL]()
}

// MARK: - Test Info
// @test-file: Tests/CameraSnapTests/CameraSnapModelTest.swift
// @test-coverage: In-memory images and destination path storage
