//
//  MLCore.swift
//  FMEA
//
//  Created by Hsieh Boh Yang on 19/3/25.
//

import Vision
import CoreML
import UIKit


public enum Emotion: String, CaseIterable {
    case angry, disgust, fear, happy, sad, surprise, neutral
    
    var name: String {
        rawValue
    }
}

extension [Emotion: Double] {
    /// Return nil when no emtion is domin±ed
    var dominantEmotion: Emotion? {
        self.max { a, b in a.value < b.value }?.key
    }
}

public struct EmotionAnalysis {
    var region: CGRect
    var emotion: [Emotion: Double]
    var dominantEmotion: Emotion
}

class MLCore {
    private let faceImageTool = FaceImageTool()
    private var mlModel: VNCoreMLModel?
    
    func analyze(cgImage: CGImage) throws -> [EmotionAnalysis] {
        if mlModel == nil {
            self.mlModel = try makeMLModel()
        }
        
        let faces = try faceImageTool.extractFaces(from: cgImage)
        
        return try faces.compactMap { (face) -> EmotionAnalysis? in
            let boundingBox = face.boundingBox
            guard let faceImage = faceImageTool.cropFace(from: cgImage, boundingBox: boundingBox) else {
                return nil
            }
            
            guard let preprocessedFaceImage = faceImageTool.preprocessImage(image: faceImage) else {
                return nil
            }
            
            let request = VNCoreMLRequest(model: mlModel!)
            let handler = VNImageRequestHandler(cgImage: preprocessedFaceImage)
            try handler.perform([request])
            
            guard let observations = request.results as? [VNCoreMLFeatureValueObservation],
                  let firstObservation = observations.first,
                  let multiArray = firstObservation.featureValue.multiArrayValue
            else {
                return nil
            }
            
            let emotionResult: [Emotion: Double] = Emotion.allCases.enumerated().reduce(into: [:]) { result, pair in
                let (index, emotionLabel) = pair
                let emotionPrediction = Double(truncating: multiArray[index]) * 100.0
                
                result[emotionLabel] = emotionPrediction
            }
            
            let dominantEmotion = emotionResult.dominantEmotion ?? .neutral
            return EmotionAnalysis(region: boundingBox, emotion: emotionResult, dominantEmotion: dominantEmotion)
        }
    }
}

extension MLCore {
    private func makeMLModel() throws -> VNCoreMLModel {
        let configuration = MLModelConfiguration()
        let classifier = try FacialExpressionModel(configuration: configuration)
        
        return try VNCoreMLModel(for: classifier.model)
    }
}
