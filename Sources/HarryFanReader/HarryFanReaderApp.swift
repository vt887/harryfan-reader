//
//  HarryFanReaderApp.swift
//  harryfan-reader
//
//  Created by Vad Tymoshyk on 9/1/25.
//

import AppKit
import SwiftUI

// Application delegate for macOS app lifecycle
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_: Notification) {
        // Ensure the app has a regular activation policy so the Menu Bar is visible
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        // Close the app when the last window (red button) is closed
        true
    }

    func applicationShouldTerminate(_: NSApplication) -> NSApplication.TerminateReply {
        let alert = NSAlert()
        alert.messageText = "Quit HarryFanReader?"
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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(fontManager)
                .environmentObject(bookmarkManager)
                .environmentObject(recentFilesManager)
                .frame(minWidth: 600, minHeight: 520)
                .colorScheme(AppSettings.appearance == .dark ? .dark : .light) // Apply the color scheme here based on AppSettings
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 800, height: 680)
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
