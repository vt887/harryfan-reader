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
    }

    deinit {
        if let obs = defaultsObserver {
            NotificationCenter.default.removeObserver(obs)
        }
    }

    // Public method to update visibility based on Settings.showStatusBarIcon
    func updateVisibility() {
        DispatchQueue.main.async {
            if Settings.showStatusBarIcon {
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
        guard Settings.showStatusBarIcon else { return }
        guard statusItem == nil else { return }

        // Create a status item with variable length
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            // Use a short title to ensure visibility even if no image is present
            button.title = "HF"
            button.toolTip = "HarryFan Reader"
        }

        // Build menu
        let menu = NSMenu()

        // File submenu
        let fileMenuItem = NSMenuItem(title: "File", action: nil, keyEquivalent: "")
        let fileSubmenu = NSMenu(title: "File")

        // Open...
        let openItem = NSMenuItem(title: "Open...", action: Selector("openAction:"), keyEquivalent: "o")
        openItem.target = self
        fileSubmenu.addItem(openItem)

        fileSubmenu.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(title: "Quit", action: Selector("quitAction:"), keyEquivalent: "q")
        quitItem.target = self
        fileSubmenu.addItem(quitItem)

        fileMenuItem.submenu = fileSubmenu
        menu.addItem(fileMenuItem)

        // Optionally add other top-level items here (Help, About, etc.)

        statusItem?.menu = menu
    }

    func stop() {
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
            statusItem = nil
        }
    }

    // Keep only the actions we need for the status bar menu (open and quit).
    @objc private func openAction(_ sender: Any?) {
        NotificationCenter.default.post(name: .openFileCommand, object: nil)
    }

    @objc private func quitAction(_ sender: Any?) {
        NSApp.terminate(nil)
    }
}
