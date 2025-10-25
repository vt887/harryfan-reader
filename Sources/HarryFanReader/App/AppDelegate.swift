//
//  AppDelegate.swift
//  harryfan-reader
//
//  Created by @vt887 on 10/25/25.
//

import AppKit
import Combine
import SwiftUI

// Small AppDelegate to manage activation policy and status bar startup
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var windowObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_: Notification) {
        // Request status bar visibility update based on Settings (StatusBarManager listens for this notification)
        NotificationCenter.default.post(name: Notification.Name("updateStatusBarVisibility"), object: nil)

        // Ensure PrintManager is initialized so it can observe print requests
        DebugLogger.log("AppDelegate: initializing PrintManager.shared")
        _ = PrintManager.shared

        // Set activation policy to regular so the app has a Dock icon and menus
        NSApp.setActivationPolicy(.regular)

        // Ensure the app becomes active and its window is brought to front on launch
        // Use async to allow SwiftUI windows to be created first
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            NSApp.activate(ignoringOtherApps: true)

            // Make existing windows key and set delegate so we can intercept close
            for window in NSApp.windows {
                window.makeKeyAndOrderFront(nil)
                window.delegate = self
            }

            // Observe when a window becomes main/active so we can set delegate for windows created later
            windowObserver = NotificationCenter.default.addObserver(forName: NSWindow.didBecomeMainNotification, object: nil, queue: .main) { [weak self] note in
                guard let self else { return }
                if let win = note.object as? NSWindow {
                    win.delegate = self
                }
            }
        }
    }

    deinit {
        if let obs = windowObserver {
            NotificationCenter.default.removeObserver(obs)
        }
    }

    func applicationWillTerminate(_: Notification) {
        // Request StatusBarManager to stop (StatusBarManager listens for this notification)
        NotificationCenter.default.post(name: Notification.Name("stopStatusBar"), object: nil)
    }

    // Intercept Quit (Cmd+Q / Quit menu) and confirm quit when necessary
    func applicationShouldTerminate(_: NSApplication) -> NSApplication.TerminateReply {
        guard Settings.shouldShowQuitMessage else {
            return .terminateNow
        }

        // Request the centered quit overlay to appear and cancel immediate termination.
        NotificationCenter.default.post(name: Notification.Name("showQuitOverlay"), object: nil)
        return .terminateCancel
    }

    // Intercept window close (red button) and confirm quit when necessary
    func windowShouldClose(_: NSWindow) -> Bool {
        // If the user doesn't want a quit confirmation, allow the window to close
        guard Settings.shouldShowQuitMessage else {
            return true
        }

        // Request the centered quit overlay; the overlay/key handler will call NSApp.terminate when confirmed
        NotificationCenter.default.post(name: Notification.Name("showQuitOverlay"), object: nil)

        // Return false to prevent the window from closing immediately; the overlay will handle termination if confirmed
        return false
    }
}
