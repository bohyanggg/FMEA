//
//  LiveFeedViewRepresentable.swift
//  FMEA
//
//  Created by Hsieh Boh Yang on 19/3/25.
//

import SwiftUI

struct LiveFeedViewRepresentable: UIViewControllerRepresentable {
    
    func makeUIViewController(context: Context) -> LiveFeedViewController {
        return LiveFeedViewController()
    }
    
    func updateUIViewController(_ uiViewController: LiveFeedViewController, context: Context) {}
}
