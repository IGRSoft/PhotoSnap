import Foundation

/// A finalized silent recording and its measured media duration.
public struct CameraSnapVideoModel: Sendable, Equatable {
    /// The finalized `.mov` file URL.
    public let url: URL
    /// The duration measured from the finalized media, in seconds.
    public let duration: TimeInterval

    /// Creates a model for a finalized recording.
    public init(url: URL, duration: TimeInterval) {
        self.url = url
        self.duration = duration
    }
}

// MARK: - Test Info
// @test-file: Tests/CameraSnapTests/CameraSnapVideoWriterTests.swift
// @test-coverage: Final URL and measured duration
