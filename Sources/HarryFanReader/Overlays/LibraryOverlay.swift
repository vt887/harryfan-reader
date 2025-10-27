//
//  LibraryOverlay.swift
//  harryfan-reader
//
//  Created by @vt887 on 10/26/25.
//

import SwiftUI

struct LibraryOverlay: View {
    @EnvironmentObject var recentFilesManager: RecentFilesManager
    @EnvironmentObject var overlayManager: OverlayManager

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                HStack {
                    Text("Library")
                        .font(.title2)
                        .bold()
                    Spacer()
                    Button(action: { overlayManager.removeOverlay(.library) }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
                .padding(.horizontal)

                if recentFilesManager.recentFiles.isEmpty {
                    Text("No files in library")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    List {
                        ForEach(recentFilesManager.recentFiles.indices, id: \.self) { idx in
                            let item = recentFilesManager.recentFiles[idx]
                            Button(action: {
                                NotificationCenter.default.post(name: .openRecentFileCommand, object: nil, userInfo: ["url": item.url])
                                overlayManager.removeOverlay(.library)
                            }) {
                                HStack {
                                    Text(item.displayName)
                                    Spacer()
                                    Text(item.url.lastPathComponent)
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .listStyle(.plain)
                }

                HStack {
                    Spacer()
                    Button("Close") { overlayManager.removeOverlay(.library) }
                        .keyboardShortcut(.escape, modifiers: [])
                }
                .padding(.horizontal)
            }
            .frame(maxWidth: 700, maxHeight: 480)
            .padding()
            .background(.regularMaterial)
            .cornerRadius(12)
            .shadow(radius: 20)
            .padding()
        }
    }
}

#Preview {
    LibraryOverlay()
        .environmentObject(RecentFilesManager())
        .environmentObject(OverlayManager())
}
