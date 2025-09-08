//
//  ContentView.swift
//  FMEA
//
//  Created by Hsieh Boh Yang on 19/3/25.
//

import SwiftUI

struct ContentView: View {
    @State private var logoOpacity: Double = 0.0
    @State private var logoOffset: CGFloat = 20

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image("AppIconIllustration")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160, height: 160)
                    .opacity(logoOpacity)
                    .offset(y: logoOffset)
                    .onAppear {
                        withAnimation(.easeOut(duration: 1.0)) {
                            logoOpacity = 1.0
                            logoOffset = 0
                        }
                    }
                    .padding(.top, 20)

                NavigationLink(destination: StillImageView()) {
                    Text("Still Image")
                        .font(.title2)
                        .frame(maxWidth: 200)
                }
                .buttonStyle(.borderedProminent)

                NavigationLink(destination: LiveFeedView()) {
                    Text("Live Feed")
                        .font(.title2)
                        .frame(maxWidth: 200)
                }
                .buttonStyle(.borderedProminent)
                
                NavigationLink(destination: VideoUploadView()) {
                    Text("Video Upload")
                        .font(.title2)
                        .frame(maxWidth: 200)
                }
                .buttonStyle(.borderedProminent)
            }
            .navigationTitle("Choose Mode")
        }
    }
}

#Preview {
    ContentView()
}
