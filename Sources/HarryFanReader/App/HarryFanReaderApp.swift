//
//  HarryFanReaderApp.swift
//  harryfan-reader
//
//  Created by @vt887 on 9/1/25.
//

import AppKit
import Combine
import SwiftUI

@main
struct HarryFanReaderApp: App {
    // Attach AppDelegate so StatusBarManager can be started early
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate: AppDelegate

    @StateObject private var fontManager = FontManager()
    @StateObject private var bookmarkManager = BookmarkManager()
    @StateObject private var recentFilesManager = RecentFilesManager()
    @StateObject private var document = TextDocument()
    @StateObject private var overlayManager = OverlayManager()

    var windowWidth: CGFloat { CGFloat(Settings.cols * Settings.charW) }
    var windowHeight: CGFloat { CGFloat(Settings.rows * Settings.charH) }

    var body: some Scene {
        WindowGroup {
            ContentView(document: document)
                .environmentObject(fontManager)
                .environmentObject(bookmarkManager)
                .environmentObject(recentFilesManager)
                .environmentObject(overlayManager)
                .frame(minWidth: windowWidth, minHeight: windowHeight)
                .colorScheme(Settings.appearance == .dark ? .dark : .light)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: windowWidth, height: windowHeight)
        .defaultPosition(.center)
        .commands {
            AppCommands(recentFilesManager: recentFilesManager, bookmarkManager: bookmarkManager, document: document)
        }

        SwiftUI.Settings {
            SettingsView()
                .environmentObject(fontManager)
                .environmentObject(document)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }
}
