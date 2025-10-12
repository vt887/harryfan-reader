//
//  StatusBarManager.swift
//  harryfan-reader
//
//  Created by @vt887 on 10/3/25.
//

import AppKit
import Foundation
import SwiftUI

// Manager for the macOS status bar (menu bar) icon
class StatusBarManager: NSObject, ObservableObject {
    private var statusItem: NSStatusItem?
    // popover is unused right now but kept for future use
    private var popover: NSPopover?

    @Published var isVisible = true

    private var showHideMenuItem: NSMenuItem? // Reference to update title and enabled state

    // Notification observer tokens
    private var observers: [NSObjectProtocol] = []

    override init() {
        super.init()
        DebugLogger.log("StatusBarManager: Initializing status bar manager")
        // Ensure Dock icon remains visible while app runs
        NSApp.setActivationPolicy(.regular)
        DebugLogger.log("StatusBarManager: App activation policy set to .regular (Dock icon visible)")

        createStatusBarItem()

        // Observe window lifecycle events across the app so menu can be updated
        let nc = NotificationCenter.default
        observers.append(nc.addObserver(forName: NSWindow.willCloseNotification, object: nil, queue: .main) { [weak self] notification in
            self?.windowWillClose(notification)
        })
        observers.append(nc.addObserver(forName: NSWindow.didMiniaturizeNotification, object: nil, queue: .main) { [weak self] notification in
            self?.windowDidMinimize(notification)
        })
        observers.append(nc.addObserver(forName: NSWindow.didDeminiaturizeNotification, object: nil, queue: .main) { [weak self] notification in
            self?.windowDidDeminiaturize(notification)
        })
        observers.append(nc.addObserver(forName: NSWindow.didBecomeKeyNotification, object: nil, queue: .main) { [weak self] notification in
            self?.windowDidBecomeKey(notification)
        })

        // Set initial menu state based on current window (if any)
        updateShowHideMenuState()
    }

    deinit {
        DebugLogger.log("StatusBarManager: Deinitializing status bar manager")
        // Remove observers and status item
        let nc = NotificationCenter.default
        for obs in observers {
            nc.removeObserver(obs)
        }
        observers.removeAll()
        removeStatusBarItem()
    }

    // Create the status bar item
    private func createStatusBarItem() {
        guard statusItem == nil else {
            DebugLogger.log("StatusBarManager: Status bar item already exists, skipping creation")
            return
        }

        DebugLogger.log("StatusBarManager: Creating status bar item")
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            DebugLogger.log("StatusBarManager: Setting up status bar button")
            button.title = "📖"
            button.toolTip = "HarryFan Reader"
            button.action = #selector(statusBarButtonClicked)
            button.target = self
        } else {
            DebugLogger.log("StatusBarManager: ERROR - Failed to get status bar button")
        }

        createMenu()
        DebugLogger.log("StatusBarManager: Status bar item created successfully")
    }

    // Create the status bar menu (two items: Show/Hide and Quit)
    private func createMenu() {
        DebugLogger.log("StatusBarManager: Building status bar menu")
        let menu = NSMenu()

        // Show/Hide menu item - title will be updated dynamically
        let showHideItem = NSMenuItem(title: "Show", action: #selector(showHideApp), keyEquivalent: "")
        showHideItem.target = self
        menu.addItem(showHideItem)
        showHideMenuItem = showHideItem

        menu.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(title: "Quit HarryFan Reader", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
        DebugLogger.log("StatusBarManager: Status bar menu created with Show/Hide and Quit items")
    }

    // Update the Show/Hide menu title based on the main window state
    private func updateShowHideMenuState() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            // Determine the window to consider as main app window
            let window = NSApp.mainWindow ?? NSApp.windows.first

            if let w = window {
                // If window is miniaturized or not visible, show "Show"; otherwise "Hide"
                if w.isMiniaturized || !w.isVisible {
                    self.showHideMenuItem?.title = "Show"
                    self.showHideMenuItem?.isEnabled = true
                } else {
                    self.showHideMenuItem?.title = "Hide"
                    self.showHideMenuItem?.isEnabled = true
                }
                DebugLogger.log("StatusBarManager: Updated menu for window (visible: \(w.isVisible), miniaturized: \(w.isMiniaturized)): \(self.showHideMenuItem?.title ?? "nil")")
            } else {
                // No window found - default to Show
                self.showHideMenuItem?.title = "Show"
                self.showHideMenuItem?.isEnabled = true
                DebugLogger.log("StatusBarManager: No main window found - menu set to Show")
            }
        }
    }

    // Status bar button clicked - show the main window
    @objc private func statusBarButtonClicked() {
        DebugLogger.log("StatusBarManager: Status bar button clicked")
        showMainWindow()
    }

    // Helper to show the main window (de-miniaturize or make key)
    private func showMainWindow() {
        DispatchQueue.main.async {
            if let w = NSApp.windows.first {
                if w.isMiniaturized {
                    DebugLogger.log("StatusBarManager: Deminiaturizing main window")
                    w.deminiaturize(nil)
                }
                DebugLogger.log("StatusBarManager: Making main window key and ordering front")
                w.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            } else {
                DebugLogger.log("StatusBarManager: ERROR - No main window found to show")
            }
            self.updateShowHideMenuState()
        }
    }

    // Show/Hide the main app window (menu action)
    @objc private func showHideApp() {
        DebugLogger.log("StatusBarManager: Show/Hide menu item clicked")
        DispatchQueue.main.async {
            let window = NSApp.mainWindow ?? NSApp.windows.first

            if let w = window {
                if w.isVisible && !w.isMiniaturized {
                    DebugLogger.log("StatusBarManager: Hiding main window (order out)")
                    w.orderOut(nil)
                    // Keep app active so status bar remains visible
                    NSApp.activate(ignoringOtherApps: true)
                } else {
                    DebugLogger.log("StatusBarManager: Showing main window (make key and order front)")
                    if w.isMiniaturized { w.deminiaturize(nil) }
                    w.makeKeyAndOrderFront(nil)
                    NSApp.activate(ignoringOtherApps: true)
                }
            } else {
                DebugLogger.log("StatusBarManager: ERROR - No main window found for show/hide action")
            }
            // Update menu to reflect new state
            self.updateShowHideMenuState()
        }
    }

    // Quit application
    @objc private func quitApp() {
        DebugLogger.log("StatusBarManager: Quit menu item clicked")
        NSApp.terminate(nil)
    }

    // Remove status bar item only when app is terminating
    private func removeStatusBarItem() {
        if let item = statusItem {
            DebugLogger.log("StatusBarManager: Removing status bar item (app is terminating)")
            NSStatusBar.system.removeStatusItem(item)
            statusItem = nil
        }
    }

    // MARK: - Window notification handlers

    private func windowWillClose(_ notification: Notification) {
        DebugLogger.log("StatusBarManager: windowWillClose received")
        // Update menu to Show when window is closed
        updateShowHideMenuState()
        // Keep app active so status bar icon persists
        NSApp.activate(ignoringOtherApps: true)
    }

    private func windowDidMinimize(_ notification: Notification) {
        DebugLogger.log("StatusBarManager: windowDidMinimize received")
        updateShowHideMenuState()
        NSApp.activate(ignoringOtherApps: true)
    }

    private func windowDidDeminiaturize(_ notification: Notification) {
        DebugLogger.log("StatusBarManager: windowDidDeminiaturize received")
        updateShowHideMenuState()
        NSApp.activate(ignoringOtherApps: true)
    }

    private func windowDidBecomeKey(_ notification: Notification) {
        DebugLogger.log("StatusBarManager: windowDidBecomeKey received")
        updateShowHideMenuState()
    }
}
