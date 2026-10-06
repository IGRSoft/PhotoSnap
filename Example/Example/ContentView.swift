//
//  ContentView.swift
//  Example
//
//  Created by Vitalii Parovishnyk on 26.11.2020.
//

import AppKit
import AVFoundation
import CameraSnap
import SwiftUI

private final class VideoPlayerLayerView: NSView {
    let playerLayer = AVPlayerLayer()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        playerLayer.videoGravity = .resizeAspect
        layer?.addSublayer(playerLayer)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func layout() {
        super.layout()
        playerLayer.frame = bounds
    }
}

private struct VideoPreview: NSViewRepresentable {
    let player: AVPlayer

    func makeNSView(context: Context) -> VideoPlayerLayerView {
        let view = VideoPlayerLayerView()
        view.playerLayer.player = player
        return view
    }

    func updateNSView(_ view: VideoPlayerLayerView, context: Context) {
        view.playerLayer.player = player
    }
}

struct ContentView: View {
    @State private var warmup: Double = 1.0
    @State private var timelapse: Double = 0.0
    
    @State private var imageType: CameraSnapConfiguration.ImageType = .png
    @State private var imageSize: CameraSnapConfiguration.OutputSize = .original
    @State private var image = Image(systemName: "swift")
    
    @State private var isSaveToFile: Bool = false
    @State private var path = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("snapshot-DATE.png").absoluteString

    @State private var videoDuration: Double = 1.0
    @State private var videoSize: CameraSnapConfiguration.OutputSize = .original
    @State private var isRecordingVideo = false
    @State private var videoStatus = "Ready"
    @State private var videoURL: URL?
    @State private var videoPlayer: AVPlayer?
    @State private var activeRecorder: CameraSnap?
    
    private var numberFormatter: NumberFormatter {
        let nf = NumberFormatter()
        nf.maximumFractionDigits = 1
        nf.minimumIntegerDigits = 2
        nf.minimumFractionDigits = 1
        
        return nf
    }
    
    var body: some View {
        TabView {
            imageTab
                .tabItem {
                    Label("Image", systemImage: "photo")
                }

            videoTab
                .tabItem {
                    Label("Video", systemImage: "video")
                }
        }
        .padding(16)
        .frame(width: 520, height: 500)
    }

    private var imageTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Menu("Image Type: (\(imageType.rawValue))") {
                ForEach(CameraSnapConfiguration.ImageType.allCases, id: \.self) { type in
                    Button(type.rawValue) {
                        imageType = type
                    }
                }
            }

            sizePicker("Image Size", selection: $imageSize)

            HStack {
                Text("Warmup:")
                Slider(value: $warmup, in: 0...10, step: 1.0)
                Text(numberFormatter.string(for: warmup)!)
            }
            HStack {
                Text("Timelapse:")
                Slider(value: $timelapse, in: 0...10, step: 0.5)
                Text(numberFormatter.string(for: timelapse)!)
            }
            HStack {
                Button("Take Photo") {
                    takePhoto()
                }
                Toggle("Save to file", isOn: $isSaveToFile)
            }

            image
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(height: 180)

            Text("Image Path: \(path)")
                .lineLimit(2)
                .textSelection(.enabled)
        }
        .padding(20)
    }

    private var videoTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            sizePicker("Video Size", selection: $videoSize)

            HStack {
                Text("Warmup:")
                Slider(value: $warmup, in: 0...10, step: 1.0)
                Text(numberFormatter.string(for: warmup)!)
            }
            HStack {
                Text("Duration:")
                Slider(value: $videoDuration, in: 1...5, step: 1.0)
                    .accessibilityIdentifier("videoDurationSlider")
                Text("\(Int(videoDuration)) s")
                    .frame(width: 32, alignment: .trailing)
            }
            HStack {
                Button(isRecordingVideo ? "Recording…" : "Record Video") {
                    recordVideo()
                }
                .disabled(isRecordingVideo)
                .accessibilityIdentifier("recordVideoButton")

                Button("Open Video") {
                    if let videoURL {
                        NSWorkspace.shared.open(videoURL)
                    }
                }
                .disabled(videoURL == nil || isRecordingVideo)
                .accessibilityIdentifier("openVideoButton")
            }

            Group {
                if let videoPlayer {
                    VideoPreview(player: videoPlayer)
                        .onTapGesture {
                            if videoPlayer.timeControlStatus == .playing {
                                videoPlayer.pause()
                            } else {
                                if videoPlayer.currentTime() >= videoPlayer.currentItem?.duration ?? .zero {
                                    videoPlayer.seek(to: .zero)
                                }
                                videoPlayer.play()
                            }
                        }
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.quaternary)
                        VStack(spacing: 8) {
                            Image(systemName: "video")
                                .font(.largeTitle)
                            Text("The last recording will appear here")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .accessibilityIdentifier("videoPreview")

            Text("Status: \(videoStatus)")
                .accessibilityIdentifier("videoStatus")
            Text("Video Path: \(videoURL?.path ?? "—")")
                .lineLimit(3)
                .textSelection(.enabled)
                .accessibilityIdentifier("videoPath")

            Spacer()
        }
        .padding(20)
    }

    private func sizePicker(_ title: String,
                            selection: Binding<CameraSnapConfiguration.OutputSize>) -> some View {
        Picker(title, selection: selection) {
            ForEach(CameraSnapConfiguration.OutputSize.allCases, id: \.self) { size in
                Text(size.rawValue).tag(size)
            }
        }
        .pickerStyle(.segmented)
    }
    
    func takePhoto() {
        let ps = CameraSnap()
        ps.cameraSnapConfiguration.isSaveToFile = isSaveToFile
        ps.cameraSnapConfiguration.imageSize = imageSize
        ps.fetchSnapshot(withWarmup: Int(warmup), withTimelapse: timelapse) { photoModel in
            if let img = photoModel.images.last {
                self.image = Image(nsImage: img)
            }
            
            if let picturePath = photoModel.paths.last {
                path = picturePath.absoluteString
            }
            else {
                path = "In memory"
            }
        }
    }

    func recordVideo() {
        let recorder = CameraSnap()
        recorder.cameraSnapConfiguration.videoSize = videoSize
        activeRecorder = recorder
        isRecordingVideo = true
        videoStatus = "Warming up camera…"

        recorder.recordVideo(for: videoDuration, withWarmup: Int(warmup)) { result in
            isRecordingVideo = false
            activeRecorder = nil

            switch result {
            case let .success(video):
                videoURL = video.url
                videoPlayer?.pause()
                videoPlayer = AVPlayer(url: video.url)
                videoPlayer?.isMuted = true
                videoPlayer?.actionAtItemEnd = .pause
                videoPlayer?.play()
                videoStatus = String(format: "Saved %.2f s silent MOV", video.duration)
            case let .failure(error):
                videoStatus = "Failed: \(error)"
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
