# FMEA (Facial Micro-Expression Analysis) iOS App

FMEA is an iOS mobile application that performs **real-time facial micro-expression analysis** using **Core ML** and **Vision**.  
It was developed as part of my Final Year Project at **Nanyang Technological University (NTU)** to explore how AI can enhance **psychological therapy** by giving therapists deeper insights into their patients’ emotions.

Unlike traditional observation-based methods, FMEA analyzes subtle, involuntary facial movements (micro-expressions) that often reveal true emotions—even when individuals consciously suppress them.  

---

## 🎯 Motivation & Objectives

Understanding genuine emotions is critical in psychotherapy, yet patients often conceal or mask them.  
FMEA bridges this gap by providing:

- **Objective emotional feedback** to complement therapists’ observations  
- **Real-time, on-device analysis** for privacy and responsiveness  
- **A user-friendly mobile app** deployable in clinical or telehealth contexts  

This project demonstrates how **AI + mobile technologies** can work together to support **mental health care**.

---

## 📱 Features

- **Still Image Mode**  
  - Import a photo from the gallery  
  - Detects faces and classifies emotions with bounding boxes  

- **Live Feed Mode**  
  - Uses the iPhone’s front-facing camera  
  - Performs real-time face detection and emotion classification  
  - Displays bounding boxes and emotion labels directly on the feed  

- **Video Upload Mode**  
  - Upload videos from the photo library  
  - Choose a sampling rate (Low, Medium, High) to balance accuracy vs. speed  
  - Generates a detailed **Emotion Report**:
    - Pie chart of emotion distribution  
    - Duration and percentage of each emotion  
    - Video duration and sampling rate used  

---

## ⚙️ Tech Stack & Architecture

- **Language & Tools**
  - Swift 5, Xcode 16.2  
  - Runs on iOS 13+ (tested on iPhone 14, iOS 18.3.1)  

- **Frameworks & Libraries**
  - **SwiftUI + UIKit** – UI design  
  - **Vision** – Face detection & landmarks  
  - **CoreImage** – Image preprocessing (grayscale, resizing, normalization)  
  - **CoreML** – On-device CNN model for emotion classification  
  - **AVFoundation** – Video capture & processing  
  - **PhotosUI** – Image & video selection  
  - **Charts** – Emotion distribution visualization  

- **Machine Learning**
  - CNN trained on **FER2013 dataset**  
  - Model conversion: TensorFlow → Core ML (`coremltools`)  
  - Entirely on-device (no server needed → better privacy, no latency)  

---

## 📂 Project Structure

```
FMEA/
 ├── ContentView.swift        # Main entry screen
 ├── StillImage/              # Still image analysis feature
 ├── LiveFeed/                # Real-time camera feed feature
 ├── VideoUpload/             # Video upload + Emotion Report
 ├── FaceImageTool.swift      # Utilities for image preprocessing
 ├── MLCore.swift             # CoreML model integration
 └── FMEA.xcodeproj           # Xcode project file
```

---

## 🚀 Getting Started

### Requirements
- macOS with **Xcode 16.2+**
- iPhone running **iOS 13+** (simulator not supported due to camera requirement)
- Camera & Photo Library permissions enabled

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/<YOUR_USERNAME>/FMEA.git
   cd FMEA
   ```
2. Open in Xcode:
   ```bash
   open FMEA.xcodeproj
   ```
3. Select your device → Build & Run (**⌘R**).

---

## 🔮 Future Work

- Explore **attention-based CNNs** (e.g., CBAM, Vision Transformers) to improve accuracy  
- Train on larger, more diverse datasets for robustness  
- Add therapist-focused features:
  - Session history & trend reports  
  - Exportable emotion logs  
  - Integration with telehealth platforms  

---

## 👨‍💻 About This Project

- Developed by: **Hsieh Boh Yang**  
- Degree: **BSc Computer Science, NTU (2025)**  
- Supervisor: **Prof. Zheng Jianmin**  

This project highlights my interests in:
- **AI/ML for healthcare**  
- **iOS app development (SwiftUI, CoreML, Vision)**  
- **Privacy-first on-device AI**  

---

## 📜 License

This project is licensed under the [MIT License](LICENSE).

---

## 🙏 Acknowledgements

- **NTU College of Computing and Data Science** for supporting this project  
- **Prof. Zheng Jianmin** for his guidance  
- Open-source contributors of **FER2013** and **DeepFace** models  
