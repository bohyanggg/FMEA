//
//  ContentView.swift
//  FMEA
//
//  Created by Hsieh Boh Yang on 19/3/25.
//

import SwiftUI
import PhotosUI
import Vision

struct FaceBoundingBox: Identifiable {
    let id = UUID()
    let rect: CGRect
    let emotion: Emotion
    let index: Int
}

struct StillImageView: View {
    @State private var detectedEmotions: [Emotion] = []
    @State private var selectedImage: UIImage?
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var faceBoundingBoxes: [FaceBoundingBox] = []
    @State private var showFaceLabels: Bool = true
    @State private var noFacesDetected: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                if let image = selectedImage {
                    GeometryReader { geo in
                        let imageSize = geo.size.width
                        ScrollView([.vertical], showsIndicators: true) {
                            ZStack(alignment: .topLeading) {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: imageSize)
                                    .cornerRadius(12)

                                GeometryReader { overlayGeo in
                                    ForEach(Array(faceBoundingBoxes.enumerated()), id: \.element.id) { index, box in
                                        ZStack(alignment: .topLeading) {
                                            Rectangle()
                                                .stroke(Color.yellow, lineWidth: 2)
                                                .frame(width: box.rect.width * overlayGeo.size.width,
                                                       height: box.rect.height * overlayGeo.size.height)
                                                .position(x: box.rect.midX * overlayGeo.size.width,
                                                          y: (1 - box.rect.midY) * overlayGeo.size.height)

                                            if showFaceLabels {
                                                Text("#\(box.index)")
                                                    .font(.caption)
                                                    .foregroundColor(.white)
                                                    .padding(4)
                                                    .background(Color.black.opacity(0.6))
                                                    .cornerRadius(4)
                                                    .offset(x: box.rect.minX * overlayGeo.size.width,
                                                            y: (1 - box.rect.minY) * overlayGeo.size.height - 20)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .frame(width: imageSize, height: imageSize)
                    }
                    .frame(height: UIScreen.main.bounds.width)
                } else {
                    Text("Select an image for analysis")
                        .foregroundColor(.gray)
                        .frame(height: UIScreen.main.bounds.width)
                }
            }

            // Display emotions
            if noFacesDetected {
                Text("No faces detected in this image 💀")
                    .foregroundColor(.gray)
            } else if detectedEmotions.isEmpty {
                Text("No emotions detected yet 😐")
                    .foregroundColor(.gray)
            } else {
                VStack(alignment: .leading) {
                    Text("Detected Emotion(s):")
                        .font(.headline)
                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(Array(faceBoundingBoxes.enumerated()), id: \.element.id) { _, box in
                                Text("#\(box.index): \(box.emotion.rawValue.capitalized)")
                                    .font(.title2)
                                    .padding(.vertical, 2)
                            }
                        }
                    }
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(.horizontal)
            }

            // Toggle button for face labels
            Button(action: {
                showFaceLabels.toggle()
            }) {
                Label(showFaceLabels ? "Hide Labels" : "Show Labels", systemImage: "number.square")
                    .font(.subheadline)
            }
            .buttonStyle(.bordered)

            // Photos picker button
            PhotosPicker(selection: $photosPickerItem, matching: .images, photoLibrary: .shared()) {
                Label("Select Photo", systemImage: "photo.on.rectangle")
                    .font(.headline)
            }
            .buttonStyle(.bordered)

            // Analyze button
            if selectedImage != nil {
                Button("Analyze Image") {
                    analyzeEmotion()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .onChange(of: photosPickerItem) { _, _ in
            Task {
                if let loaded = try? await photosPickerItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: loaded) {
                    selectedImage = uiImage
                    detectedEmotions = []
                    faceBoundingBoxes = []
                    noFacesDetected = false
                }
            }
        }
    }

    func analyzeEmotion() {
        guard let cgImage = selectedImage?.cgImage else {
            print("Failed to convert UIImage to CGImage")
            return
        }

        // Face Detection
        let faceDetectionRequest = VNDetectFaceRectanglesRequest { request, error in
            // Initial face bounding box drawing handled by emotion analysis below
        }

        do {
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
            try handler.perform([faceDetectionRequest])

            // Emotion Analysis (existing)
            let analysis = try MLCore().analyze(cgImage: cgImage)
            faceBoundingBoxes = analysis.enumerated().map { (index, result) in
                FaceBoundingBox(rect: result.region, emotion: result.dominantEmotion, index: index + 1)
            }
            detectedEmotions = faceBoundingBoxes.map { $0.emotion }
            noFacesDetected = faceBoundingBoxes.isEmpty
        } catch {
            print("Analysis failed: \(error)")
        }
    }
}

#Preview {
    StillImageView()
}
