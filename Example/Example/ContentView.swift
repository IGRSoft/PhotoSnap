//
//  ContentView.swift
//  Example
//
//  Created by Vitalii Parovishnyk on 26.11.2020.
//

import SwiftUI
import PhotoSnap

struct ContentView: View {
    @State private var warmup: Double = 1.0
    @State private var timelapse: Double = 0.0
    
    @State private var imageType: PhotoSnapConfiguration.ImageType = .png
    @State private var image = Image(systemName: "swift")
    
    @State private var isSaveToFile: Bool = false
    @State private var path = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("snapshot-DATE.png").absoluteString
    
    private var numberFormatter: NumberFormatter {
        let nf = NumberFormatter()
        nf.maximumFractionDigits = 1
        nf.minimumIntegerDigits = 2
        nf.minimumFractionDigits = 1
        
        return nf
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 32.0) {
            VStack {
                Menu("Image Type: (\(imageType.rawValue))") {
                    Button(PhotoSnapConfiguration.ImageType.png.rawValue) {
                        imageType = .png
                    }
                    Button(PhotoSnapConfiguration.ImageType.tiff.rawValue) {
                        imageType = .tiff
                    }
                    Button(PhotoSnapConfiguration.ImageType.jpeg.rawValue) {
                        imageType = .jpeg
                    }
                    Button(PhotoSnapConfiguration.ImageType.bmp.rawValue) {
                        imageType = .bmp
                    }
                    Button(PhotoSnapConfiguration.ImageType.gif.rawValue) {
                        imageType = .gif
                    }
                }
                HStack{
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
                    .padding()
                    Toggle(isOn: $isSaveToFile) {
                        Text("Save to file")
                    }
                }
                
            }
            VStack {
                image
                    .resizable()
                    .scaledToFit().frame(width: 468, height: 468, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
            }
            Text("Image Path: \(path)")
        }
        .padding(16.0)
        .frame(width: 500.0)
    }
    
    func takePhoto() {
        let ps = PhotoSnap()
        ps.photoSnapConfiguration.isSaveToFile = isSaveToFile
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
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
