//
//  LiveFeedViewController.swift
//  FMEA
//
//  Created by Hsieh Boh Yang on 19/3/25.
//

import AVFoundation
import UIKit
import Vision

class LiveFeedViewController: UIViewController {
    private let faceImageTool = FaceImageTool()
    private let mlCore = MLCore()
    
    private let captureSession = AVCaptureSession()
    private lazy var previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private var faceLayers: [CAShapeLayer] = []
    
    private let emotionLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.textAlignment = .center
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        captureSession.startRunning()
        self.view.addSubview(emotionLabel)
        emotionLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            emotionLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            emotionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emotionLabel.widthAnchor.constraint(equalToConstant: 200),
            emotionLabel.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.previewLayer.frame = self.view.frame
    }
    
    private func setupCamera() {
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .front)
        if let device = deviceDiscoverySession.devices.first {
            if let deviceInput = try? AVCaptureDeviceInput(device: device) {
                if captureSession.canAddInput(deviceInput) {
                    captureSession.addInput(deviceInput)
                    
                    setupPreview()
                }
            }
        }
    }
    
    private func setupPreview() {
        self.previewLayer.videoGravity = .resizeAspectFill
        self.view.layer.addSublayer(self.previewLayer)
        self.previewLayer.frame = self.view.frame
        
        self.videoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA)] as [String : Any]

        self.videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera queue"))
        self.captureSession.addOutput(self.videoDataOutput)
        
        let videoConnection = self.videoDataOutput.connection(with: .video)
        videoConnection?.videoOrientation = .portrait
    }
}

extension LiveFeedViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let faceDetectionRequest = VNDetectFaceRectanglesRequest { [weak self] request, error in
            DispatchQueue.main.async {
                guard let self = self else { return }

                self.faceLayers.forEach { $0.removeFromSuperlayer() }
                self.faceLayers.removeAll()

                guard let observations = request.results as? [VNFaceObservation],
                      let mainFace = observations.sorted(by: { $0.boundingBox.width * $0.boundingBox.height > $1.boundingBox.width * $1.boundingBox.height }).first else {
                    self.emotionLabel.text = "No face detected"
                    return
                }

                let faceBoundingBox = self.previewLayer.layerRectConverted(fromMetadataOutputRect: observations[0].boundingBox)
                self.drawBoundingBox(faceBoundingBox)

                // Emotion analysis
                self.performEmotionAnalysis(on: observations[0], pixelBuffer: CMSampleBufferGetImageBuffer(sampleBuffer))
            }
        }

        let handler = VNImageRequestHandler(cvPixelBuffer: imageBuffer, orientation: .leftMirrored, options: [:])
        try? handler.perform([faceDetectionRequest])
    }
    
    private func drawBoundingBox(_ boundingBox: CGRect) {
        let faceLayer = CAShapeLayer()
        faceLayer.path = UIBezierPath(rect: boundingBox).cgPath
        faceLayer.fillColor = UIColor.clear.cgColor
        faceLayer.strokeColor = UIColor.yellow.cgColor
        faceLayer.lineWidth = 2

        self.view.layer.addSublayer(faceLayer)
        self.faceLayers.append(faceLayer)
    }
    
    private func performEmotionAnalysis(on faceObservation: VNFaceObservation, pixelBuffer: CVPixelBuffer?) {
        guard let pixelBuffer = pixelBuffer else {
            print("Pixel buffer is nil.")
            return
        }

        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()

        guard let frameCGImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            print("Failed to create CGImage from frame.")
            return
        }

        // Pass the entire frame clearly to MLCore
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let analyses = try self.mlCore.analyze(cgImage: frameCGImage)
                guard let analysis = analyses.first else {
                    print("Analysis returned empty result.")
                    DispatchQueue.main.async {
                        self.emotionLabel.text = "Neutral"
                    }
                    return
                }

                DispatchQueue.main.async {
                    self.emotionLabel.text = analysis.dominantEmotion.rawValue.capitalized
                    print("Dominant emotion detected: \(analysis.dominantEmotion.rawValue)")
                }
            } catch {
                print("Emotion analysis error: \(error)")
            }
        }
    }
    
    
//
//    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
//        
//        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
//          return
//        }
//
//        let faceDetectionRequest = VNDetectFaceLandmarksRequest(completionHandler: { (request: VNRequest, error: Error?) in
//            DispatchQueue.main.async {
//                self.faceLayers.forEach({ drawing in drawing.removeFromSuperlayer() })
//
//                if let observations = request.results as? [VNFaceObservation] {
//                    self.handleFaceDetectionObservations(observations: observations)
//                }
//            }
//        })
//
//        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: imageBuffer, orientation: .leftMirrored, options: [:])
//
//        do {
//            try imageRequestHandler.perform([faceDetectionRequest])
//        } catch {
//          print(error.localizedDescription)
//        }
//    }
//    
//    private func handleFaceDetectionObservations(observations: [VNFaceObservation]) {
//        for observation in observations {
//            let faceRectConverted = self.previewLayer.layerRectConverted(fromMetadataOutputRect: observation.boundingBox)
//            let faceRectanglePath = CGPath(rect: faceRectConverted, transform: nil)
//            
//            let faceLayer = CAShapeLayer()
//            faceLayer.path = faceRectanglePath
//            faceLayer.fillColor = UIColor.clear.cgColor
//            faceLayer.strokeColor = UIColor.yellow.cgColor
//            
//            self.faceLayers.append(faceLayer)
//            self.view.layer.addSublayer(faceLayer)
//            
//            //FACE LANDMARKS
//            if let landmarks = observation.landmarks {
//                if let leftEye = landmarks.leftEye {
//                    self.handleLandmark(leftEye, faceBoundingBox: faceRectConverted)
//                }
//                if let leftEyebrow = landmarks.leftEyebrow {
//                    self.handleLandmark(leftEyebrow, faceBoundingBox: faceRectConverted)
//                }
//                if let rightEye = landmarks.rightEye {
//                    self.handleLandmark(rightEye, faceBoundingBox: faceRectConverted)
//                }
//                if let rightEyebrow = landmarks.rightEyebrow {
//                    self.handleLandmark(rightEyebrow, faceBoundingBox: faceRectConverted)
//                }
//
//                if let nose = landmarks.nose {
//                    self.handleLandmark(nose, faceBoundingBox: faceRectConverted)
//                }
//
//                if let outerLips = landmarks.outerLips {
//                    self.handleLandmark(outerLips, faceBoundingBox: faceRectConverted)
//                }
//                if let innerLips = landmarks.innerLips {
//                    self.handleLandmark(innerLips, faceBoundingBox: faceRectConverted)
//                }
//            }
//        }
//    }
//    
//    private func handleLandmark(_ eye: VNFaceLandmarkRegion2D, faceBoundingBox: CGRect) {
//        let landmarkPath = CGMutablePath()
//        let landmarkPathPoints = eye.normalizedPoints
//            .map({ eyePoint in
//                CGPoint(
//                    x: eyePoint.y * faceBoundingBox.height + faceBoundingBox.origin.x,
//                    y: eyePoint.x * faceBoundingBox.width + faceBoundingBox.origin.y)
//            })
//        landmarkPath.addLines(between: landmarkPathPoints)
//        landmarkPath.closeSubpath()
//        let landmarkLayer = CAShapeLayer()
//        landmarkLayer.path = landmarkPath
//        landmarkLayer.fillColor = UIColor.clear.cgColor
//        landmarkLayer.strokeColor = UIColor.green.cgColor
//
//        self.faceLayers.append(landmarkLayer)
//        self.view.layer.addSublayer(landmarkLayer)
//    }
}
