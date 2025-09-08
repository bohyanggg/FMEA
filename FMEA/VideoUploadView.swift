//
//  VideoUploadView.swift
//  FMEA
//
//  Created by Hsieh Boh Yang on 22/3/25.
//

import SwiftUI
import PhotosUI
import Charts
import AVFoundation

let emotionColors: [String: Color] = [
    "Happy": .yellow,
    "Angry": .red,
    "Disgust": .green,
    "Fear": .purple,
    "Sad": .blue,
    "Surprise": .orange,
    "Neutral": .brown
]

struct EmotionSlice: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
}

enum SamplingPreset: String, CaseIterable, Identifiable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"

    var id: String { self.rawValue }

    var frameInterval: Double {
        switch self {
        case .low: return 2.0
        case .medium: return 0.2
        case .high: return 0.05
        }
    }
}

struct VideoUploadView: View {
    @State private var videoItem: PhotosPickerItem?
    @State private var emotionReport: [String: Double] = [:]
    @State private var processing = false
    @State private var videoDuration: Double = 0
    @State private var selectedPreset: SamplingPreset = .medium

    var body: some View {
        VStack(spacing: 20) {
            Text("Sampling Rate")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            Picker("Sampling Rate", selection: $selectedPreset) {
                Text("Low").tag(SamplingPreset.low).help("1 frame every 2.00s")
                Text("Medium").tag(SamplingPreset.medium).help("1 frame every 0.20s")
                Text("High").tag(SamplingPreset.high).help("1 frame every 0.05s")
            }
            .pickerStyle(.segmented)
            .disabled(processing)
            .padding(.bottom, 10)

            PhotosPicker(selection: $videoItem, matching: .videos) {
                Label("Select Video", systemImage: "video.fill")
                    .font(.title2)
            }
            .buttonStyle(.borderedProminent)

            if processing {
                ProgressView("Analyzing video...")
            }

            if !emotionReport.isEmpty {
                Text("Emotion Report")
                    .font(.title2)
                    .bold()

                Chart(emotionSlices) { slice in
                    SectorMark(
                        angle: .value("Percentage", slice.value),
                        innerRadius: .ratio(0.5),
                        angularInset: 1.5
                    )
                    .foregroundStyle(emotionColors[slice.label] ?? .gray)
                    .annotation(position: .overlay) {
                        Text(String(format: "%.1f%%", slice.value))
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }
                .frame(height: 250)
                .padding(.top)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Sampling Rate: 1 frame every \(String(format: "%.2f", selectedPreset.frameInterval))s")
                        .font(.subheadline)
                        .padding(.bottom, 5)

                    Text(String(format: "Total Duration: %.1f seconds", videoDuration))
                        .font(.subheadline)
                        .padding(.bottom, 5)

                    ForEach(emotionSlices) { slice in
                        let rawSeconds = (slice.value / 100.0) * videoDuration
                        HStack {
                            Circle()
                                .fill(emotionColors[slice.label] ?? .gray)
                                .frame(width: 10, height: 10)
                            Text("\(slice.label): \(String(format: "%.1f", slice.value))% (\(String(format: "%.1f", rawSeconds))s)")
                                .font(.subheadline)
                        }
                    }
                }
                .padding(.top, 10)
            }
        }
        .padding()
        .onChange(of: videoItem) { _, _ in
            if let videoItem = videoItem {
                processVideo(item: videoItem)
            }
        }
    }

    var emotionSlices: [EmotionSlice] {
        let total = emotionReport.values.reduce(0, +)
        return emotionReport
            .map { (key, value) in
                EmotionSlice(label: key.capitalized, value: (value / total) * 100)
            }
            .sorted { $0.value > $1.value }
    }

    func processVideo(item: PhotosPickerItem) {
        processing = true
        emotionReport = [:]

        print("Selected video item: \(item)")

        Task {
            do {
                if let data = try await item.loadTransferable(type: Data.self) {
                    // Save the data to a temporary file
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("selectedVideo.mov")
                    try data.write(to: tempURL)
                    print("Saved video to temp URL: \(tempURL)")
                    analyzeVideo(at: tempURL)
                } else {
                    print("Video data is nil")
                    processing = false
                }
            } catch {
                print("Failed to load video data: \(error)")
                processing = false
            }
        }
    }

    func analyzeVideo(at url: URL) {
        Task {
            let analyzer = VideoEmotionAnalyzer()
            let asset = AVURLAsset(url: url)
            do {
                videoDuration = try await asset.load(.duration).seconds
            } catch {
                print("Failed to load video duration: \(error)")
                videoDuration = 0
            }
            emotionReport = await analyzer.analyze(url: url, frameInterval: selectedPreset.frameInterval)
            processing = false
            do {
                try FileManager.default.removeItem(at: url)
                print("Temporary video file deleted successfully.")
            } catch {
                print("Failed to delete temporary video file: \\(error)")
            }
        }
    }
}
