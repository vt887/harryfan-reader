//
//  HarryFanReaderApp.swift
//  harryfan-reader
//
//  Created by @vt887 on 9/1/25.
//

import AppKit
import SwiftUI

// Application delegate for macOS app lifecycle
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_: Notification) {
        // Ensure the app has a regular activation policy so the Menu Bar is visible
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        // Set default settings if not already set
        if UserDefaults.standard.object(forKey: "enableAntiAliasing") == nil {
            UserDefaults.standard.set(true, forKey: "enableAntiAliasing")
        }
        if UserDefaults.standard.object(forKey: "showLineNumbers") == nil {
            UserDefaults.standard.set(false, forKey: "showLineNumbers")
        }

        // Enable anti-aliasing for all windows (if enabled in settings)
        NSWindow.allowsAutomaticWindowTabbing = false
        if Settings.enableAntiAliasing {
            if let window = NSApp.windows.first {
                window.contentView?.layer?.contentsScale = NSScreen.main?.backingScaleFactor ?? 2.0
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        // Keep the app running when window is closed
        true
    }

    func applicationShouldTerminate(_: NSApplication) -> NSApplication.TerminateReply {
        .terminateNow
    }
}

// Main app entry point and scene configuration
@main
struct HarryFanReaderApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var fontManager = FontManager()
    @StateObject private var bookmarkManager = BookmarkManager()
    @StateObject private var recentFilesManager = RecentFilesManager()
    @StateObject private var document: TextDocument
    @StateObject private var overlayManager = OverlayManager()

    var windowWidth: CGFloat { CGFloat(Settings.cols * Settings.charW) }
    var windowHeight: CGFloat { CGFloat(Settings.rows * Settings.charH) } // Match ScreenView size exactly

    init() {
        let doc = TextDocument()
        _document = StateObject(wrappedValue: doc)
    }

    var body: some Scene {
        WindowGroup {
            ContentView(document: document)
                .environmentObject(fontManager)
                .environmentObject(bookmarkManager)
                .environmentObject(recentFilesManager)
                .environmentObject(overlayManager)
                .frame(minWidth: windowWidth, minHeight: windowHeight)
                .colorScheme(Settings.appearance == .dark ? .dark : .light) // Apply the color scheme here based on Settings
        }
        .windowStyle(.titleBar)
        .defaultSize(width: windowWidth, height: windowHeight)
        .defaultPosition(.center)
        .commands {
            AppCommands(recentFilesManager: recentFilesManager, bookmarkManager: bookmarkManager)
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
