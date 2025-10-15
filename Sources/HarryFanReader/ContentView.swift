//
//  ContentView.swift
//  harryfan-reader
//
//  Created by @vt887 on 9/1/25.
//

import AppKit
import Foundation
import SwiftUI
import UniformTypeIdentifiers

// Main content view for the app
struct ContentView: View {
    @ObservedObject var document: TextDocument
    @EnvironmentObject var fontManager: FontManager
    @EnvironmentObject var bookmarkManager: BookmarkManager
    @EnvironmentObject var recentFilesManager: RecentFilesManager
    @EnvironmentObject var overlayManager: OverlayManager

    @State private var showingFilePicker = false
    @State private var showingBookmarks = false
    @State private var showingSettings = false
    @State private var showingGotoDialog = false
    @State private var gotoLineNumber = ""

    init(document: TextDocument) {
        self.document = document
        DebugLogger.log("ContentView initializing...")
    }

    var body: some View {
        VStack(spacing: 0) {
            TitleBar(document: document)
            MainContentScreenView(document: document, recentFilesManager: recentFilesManager, showingFilePicker: $showingFilePicker)
            ActionBar(document: document)
        }
        .frame(
            width: CGFloat(AppSettings.cols * AppSettings.charW),
            height: CGFloat(AppSettings.rows * AppSettings.charH),
        )
        .background(Colors.theme.background)
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(fontManager)
                .environmentObject(document)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .applyNotifications(document: document,
                            showingBookmarks: $showingBookmarks,
                            showingFilePicker: $showingFilePicker)
        // Remove alert, use overlay for quit confirmation
        .onChange(of: document.shouldShowQuitMessage) { _, showQuit in
            if showQuit {
                overlayManager.addOverlay(.quit)
            }
        }
    }
}

#Preview {
    ContentView(document: TextDocument())
        .environmentObject(FontManager())
        .environmentObject(BookmarkManager())
        .environmentObject(RecentFilesManager())
}
