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
class StatusBarManager: ObservableObject {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?

    @Published var isVisible = true

    init() {
        DebugLogger.log("StatusBarManager: Initializing status bar manager")
        createStatusBarItem()
        // Ensure the status bar item persists even when app is hidden
        NSApp.setActivationPolicy(.accessory)
        DebugLogger.log("StatusBarManager: App activation policy set to accessory")
    }

    deinit {
        DebugLogger.log("StatusBarManager: Deinitializing status bar manager")
        // Only remove when app is actually terminating
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

        // Set the icon
        if let button = statusItem?.button {
            DebugLogger.log("StatusBarManager: Setting up status bar button")
            // You can use a custom icon here or a system icon
            // For now, using a text-based icon
            button.title = "📖"
            button.toolTip = "HarryFan Reader"
            button.action = #selector(statusBarButtonClicked)
            button.target = self
            DebugLogger.log("StatusBarManager: Status bar button configured with title '📖' and tooltip 'HarryFan Reader'")
        } else {
            DebugLogger.log("StatusBarManager: ERROR - Failed to get status bar button")
        }

        // Create the menu
        DebugLogger.log("StatusBarManager: Creating status bar menu")
        createMenu()
        DebugLogger.log("StatusBarManager: Status bar item created successfully")
    }

    // Create the status bar menu
    private func createMenu() {
        DebugLogger.log("StatusBarManager: Building status bar menu")
        let menu = NSMenu()

        // Show/Hide App
        let showHideItem = NSMenuItem(title: "Show HarryFan Reader", action: #selector(showHideApp), keyEquivalent: "")
        showHideItem.target = self
        menu.addItem(showHideItem)
        DebugLogger.log("StatusBarManager: Added 'Show HarryFan Reader' menu item")

        // Add About menu item
        let aboutItem = NSMenuItem(title: "About HarryFan Reader", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)
        DebugLogger.log("StatusBarManager: Added 'About HarryFan Reader' menu item")

        menu.addItem(NSMenuItem.separator())

        // Quick Actions
        let openItem = NSMenuItem(title: "Open File...", action: #selector(openFile), keyEquivalent: "o")
        openItem.target = self
        menu.addItem(openItem)
        DebugLogger.log("StatusBarManager: Added 'Open File...' menu item (⌘O)")

        // Remove 'Search' menu item
        // let searchItem = NSMenuItem(title: "Search", action: #selector(showSearch), keyEquivalent: "f")
        // menu.addItem(searchItem)
        // DebugLogger.log("StatusBarManager: Added 'Search' menu item (⌘F)")

        menu.addItem(NSMenuItem.separator())

        // Settings
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(showSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        DebugLogger.log("StatusBarManager: Added 'Settings...' menu item (⌘,)")

        menu.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(title: "Quit HarryFan Reader", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        DebugLogger.log("StatusBarManager: Added 'Quit HarryFan Reader' menu item (⌘Q)")

        statusItem?.menu = menu
        DebugLogger.log("StatusBarManager: Status bar menu created with \(menu.items.count) items")
    }

    // Status bar button clicked
    @objc private func statusBarButtonClicked() {
        DebugLogger.log("StatusBarManager: Status bar button clicked")
        // Always show the app window when status bar icon is clicked
        if let window = NSApp.windows.first {
            DebugLogger.log("StatusBarManager: Showing main window and activating app")
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        } else {
            DebugLogger.log("StatusBarManager: ERROR - No main window found")
        }
    }

    // Show/Hide the main app window
    @objc private func showHideApp() {
        DebugLogger.log("StatusBarManager: Show/Hide app menu item clicked")
        guard let window = NSApp.windows.first else {
            DebugLogger.log("StatusBarManager: ERROR - No main window found for show/hide")
            return
        }

        if window.isVisible {
            DebugLogger.log("StatusBarManager: Hiding main window (keeping status bar icon)")
            // Ensure the status bar icon remains visible by setting accessory policy
            NSApp.setActivationPolicy(.accessory)
            window.orderOut(nil)
        } else {
            DebugLogger.log("StatusBarManager: Showing main window and activating app")
            // Set regular policy to allow window to appear and be focused
            NSApp.setActivationPolicy(.regular)
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    // Open file action
    @objc private func openFile() {
        DebugLogger.log("StatusBarManager: Open file menu item clicked")
        NotificationCenter.default.post(name: .openFileCommand, object: nil)
        DebugLogger.log("StatusBarManager: Posted openFileCommand notification")
    }

    // Show settings
    @objc private func showSettings() {
        DebugLogger.log("StatusBarManager: Settings menu item clicked")
        if let menuItem = NSApp.mainMenu?.item(withTitle: "Settings") {
            NSApp.mainMenu?.performActionForItem(at: menuItem.tag)
        } else {
            DebugLogger.log("StatusBarManager: No Settings menu item found. Implement settings window presentation here if needed.")
        }
        DebugLogger.log("StatusBarManager: Sent showPreferencesWindow action")
    }

    // Add About handler
    @objc private func showAbout() {
        DebugLogger.log("StatusBarManager: About menu item clicked")
        NotificationCenter.default.post(name: .showAboutOverlay, object: nil)
    }

    // Quit application
    @objc private func quitApp() {
        DebugLogger.log("StatusBarManager: Quit menu item clicked")
        NSApp.terminate(nil)
        DebugLogger.log("StatusBarManager: App termination requested")
    }

    // Remove status bar item
    private func removeStatusBarItem() {
        if let statusItem {
            DebugLogger.log("StatusBarManager: Removing status bar item")
            NSStatusBar.system.removeStatusItem(statusItem)
            self.statusItem = nil
            DebugLogger.log("StatusBarManager: Status bar item removed successfully")
        } else {
            DebugLogger.log("StatusBarManager: No status bar item to remove")
        }
    }

    // Status bar icon should always be visible until app exits
    // No toggle functionality - icon persists until app termination
}

// Extension for notification names
extension Notification.Name {
    static let showAboutOverlay = Notification.Name("showAboutOverlay")
}
