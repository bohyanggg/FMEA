//
//  VideoEmotionAnalyzer.swift
//  FMEA
//
//  Created by Hsieh Boh Yang on 22/3/25.
//

import AVFoundation
import UIKit

struct NoFaceEmotion: Hashable {}

class VideoEmotionAnalyzer {
    private let mlCore = MLCore()

    func analyze(url: URL, frameInterval: Double) async -> [String: Double] {
        print("Beginning video analysis for: \(url)")
        var emotionDurations: [String: Double] = [:]
        var noFaceDuration: Double = 0

        let asset = AVURLAsset(url: url)
        
        do {
            let duration = try await asset.load(.duration)
            let totalSeconds = CMTimeGetSeconds(duration)
            var currentTime = 0.0

            while currentTime < totalSeconds {
                if let frame = await extractFrame(from: asset, at: currentTime) {
                    if let dominantEmotion = await analyzeFrame(frame: frame) {
                        emotionDurations[dominantEmotion.rawValue, default: 0] += frameInterval
                    } else {
                        noFaceDuration += frameInterval
                    }
                } else {
                    noFaceDuration += frameInterval
                }
                currentTime += frameInterval
            }
        } catch {
            print("Error loading asset duration: \(error)")
        }

        if noFaceDuration > 0 {
            emotionDurations["No detectable face"] = noFaceDuration
        }

        return emotionDurations
    }

    private func extractFrame(from asset: AVURLAsset, at timeInSeconds: Double) async -> CGImage? {
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        let timestamp = CMTime(seconds: timeInSeconds, preferredTimescale: 600)

        return await withCheckedContinuation { continuation in
            imageGenerator.generateCGImageAsynchronously(for: timestamp) { image, _, error in
                if let error = error {
                    print("Frame extraction error: \(error)")
                    continuation.resume(returning: nil)
                } else {
                    continuation.resume(returning: image)
                }
            }
        }
    }

    private func analyzeFrame(frame: CGImage) async -> Emotion? {
        do {
            let analyses = try mlCore.analyze(cgImage: frame)
            return analyses.first?.dominantEmotion
        } catch {
            print("Frame analysis error: \(error)")
            return nil
        }
    }
}
