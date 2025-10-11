// AboutOverlay.swift
// harryfan-reader

import SwiftUI

struct AboutOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.8).edgesIgnoringSafeArea(.all)
            VStack(alignment: .center, spacing: 16) {
                Text("HarryFan Reader")
                    .font(.title)
                    .foregroundColor(.white)
                Text("A retro-style text viewer")
                    .font(.subheadline)
                    .foregroundColor(.white)
                Text("Supports CP866 encoding and MS-DOS fonts")
                    .font(.subheadline)
                    .foregroundColor(.white)
                Text("Version \(ReleaseInfo.version).\(ReleaseInfo.build)")
                    .font(.caption)
                    .foregroundColor(.white)
                Button("Close") {
                    // The parent view should set showingAbout = false
                }
                .padding(.top, 16)
            }
            .padding()
            .frame(width: 350, height: 220)
            .background(Color(.windowBackgroundColor))
            .cornerRadius(16)
            .shadow(radius: 20)
        }
    }
}

#Preview {
    AboutOverlay()
}

