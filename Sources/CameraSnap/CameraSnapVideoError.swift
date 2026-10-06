import Foundation

/// Failures from validating, capturing, writing, or finalizing a recording.
public enum CameraSnapVideoError: Error, Sendable, Equatable {
    /// The requested duration is non-finite or outside the inclusive 1–5 second range.
    case invalidDuration
    /// No camera is available for the recording.
    case deviceUnavailable
    /// The capture session could not be configured or started.
    case sessionSetupFailed
    /// Another recording already owns the capture session.
    case recordingInProgress
    /// The final `.mov` URL is invalid, unavailable, or already exists.
    case destinationUnavailable
    /// The video writer could not start or append a sample.
    case writerFailed
    /// Capture did not receive enough media before its deadline.
    case captureTimedOut
    /// The writer could not finish or the finalized asset failed validation.
    case finalizationFailed
}

// MARK: - Test Info
// @test-file: Tests/CameraSnapTests/CameraSnapVideoValidationTests.swift
// @related-tests: Tests/CameraSnapTests/CameraSnapVideoWriterTests.swift
// @test-coverage: Typed validation and recording failures
