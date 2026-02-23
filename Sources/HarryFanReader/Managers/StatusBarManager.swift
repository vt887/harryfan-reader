// StatusBarManager.swift
// Manages the status bar (menu bar) item and its menu

import AppKit
import Foundation

final class StatusBarManager: NSObject {
    static let shared = StatusBarManager()

    private var statusItem: NSStatusItem?
    private var defaultsObserver: NSObjectProtocol?

    override init() {
        super.init()
        // Observe UserDefaults changes and update status bar visibility when preference changes
        defaultsObserver = NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: .main) { [weak self] _ in
            self?.updateVisibility()
        }

        // Listen for requests from AppDelegate to update visibility or stop
        NotificationCenter.default.addObserver(forName: Notification.Name("updateStatusBarVisibility"), object: nil, queue: .main) { [weak self] _ in
            self?.updateVisibility()
        }
        NotificationCenter.default.addObserver(forName: Notification.Name("stopStatusBar"), object: nil, queue: .main) { [weak self] _ in
            self?.stop()
        }
    }

    deinit {
        if let obs = defaultsObserver {
            NotificationCenter.default.removeObserver(obs)
        }
        NotificationCenter.default.removeObserver(self)
    }

    // Public method to update visibility based on Settings.showStatusBar
    func updateVisibility() {
        DispatchQueue.main.async {
            if Settings.showStatusBar {
                if self.statusItem == nil {
                    self.start()
                }
            } else {
                if self.statusItem != nil {
                    self.stop()
                }
            }
        }
    }

    func start() {
        // Respect setting: only create status bar item when setting enabled
        guard Settings.showStatusBar else { return }
        guard statusItem == nil else { return }

        // Create a status item with variable length
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            // Use a short title to ensure visibility even if no image is present
            button.title = "HF"
            button.toolTip = "HarryFan Reader"
        }

        // Build a minimal menu with only "Show HarryFan Reader" and "Quit"
        let menu = NSMenu()

        let showItem = NSMenuItem(title: "Show HarryFan Reader", action: #selector(StatusBarManager.showAction(_:)), keyEquivalent: "")
        showItem.target = self
        menu.addItem(showItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(StatusBarManager.quitAction(_:)), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    func stop() {
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
            statusItem = nil
        }
    }

    // Keep only the actions we need for the status bar menu (open and quit).
    @objc private func openAction(_: Any?) {
        NotificationCenter.default.post(name: .openFileCommand, object: nil)
    }

    @objc private func quitAction(_: Any?) {
        // Request the quit overlay instead of terminating immediately.
        NotificationCenter.default.post(name: Notification.Name("showQuitOverlay"), object: nil)
    }

    // New action to bring the app forward and show its windows
    @objc private func showAction(_: Any?) {
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            for window in NSApp.windows {
                window.makeKeyAndOrderFront(nil)
            }
        }
    }
}
