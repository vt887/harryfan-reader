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

        // Set default anti-aliasing setting if not already set
        if UserDefaults.standard.object(forKey: "enableAntiAliasing") == nil {
            UserDefaults.standard.set(true, forKey: "enableAntiAliasing")
        }

        // Enable anti-aliasing for all windows (if enabled in settings)
        NSWindow.allowsAutomaticWindowTabbing = false
        if AppSettings.enableAntiAliasing {
            if let window = NSApp.windows.first {
                window.contentView?.layer?.contentsScale = NSScreen.main?.backingScaleFactor ?? 2.0
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        // Close the app when the last window (red button) is closed
        true
    }

    func applicationShouldTerminate(_: NSApplication) -> NSApplication.TerminateReply {
        if !AppSettings.shouldShowQuitMessage {
            return .terminateNow
        }
        // Show a confirmation dialog before quitting
        let alert = NSAlert()
        alert.messageText = "Quit \(AppSettings.appName)?"
        alert.informativeText = "Are you sure you want to quit?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Quit")
        alert.addButton(withTitle: "Cancel")
        let response = alert.runModal()
        return response == .alertFirstButtonReturn ? .terminateNow : .terminateCancel
    }
}

// Main app entry point and scene configuration
@main
struct HarryFanReaderApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var fontManager = FontManager()
    @StateObject private var bookmarkManager = BookmarkManager()
    @StateObject private var recentFilesManager = RecentFilesManager()

    var windowWidth: CGFloat { CGFloat(AppSettings.cols * AppSettings.charW) }
    var windowHeight: CGFloat { CGFloat((AppSettings.rows - 2) * AppSettings.charH) } // -2 for TitleBar and MenuBar

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(fontManager)
                .environmentObject(bookmarkManager)
                .environmentObject(recentFilesManager)
                .frame(minWidth: windowWidth, minHeight: windowHeight)
                .colorScheme(AppSettings.appearance == .dark ? .dark : .light) // Apply the color scheme here based on AppSettings
        }
        .windowStyle(.titleBar)
        .defaultSize(width: windowWidth, height: windowHeight)
        .defaultPosition(.center)
        .commands {
            AppCommands(recentFilesManager: recentFilesManager, bookmarkManager: bookmarkManager)
        }

        Settings {
            SettingsView()
                .environmentObject(fontManager)
        }
    }
}
