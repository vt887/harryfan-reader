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

    var windowSize: CGSize {
        Settings.windowSize()
    }

    init() {
        NSWindow.allowsAutomaticWindowTabbing = false
        for window in NSApplication.shared.windows {
            window.collectionBehavior.remove(.fullScreenPrimary)
            window.styleMask.remove(.fullScreen)
        }
        /// removeUnwantedMenus()
    }

    var body: some Scene {
        WindowGroup {
            ContentView(document: document)
                .environmentObject(fontManager)
                .environmentObject(bookmarkManager)
                .environmentObject(recentFilesManager)
                .environmentObject(overlayManager)
                .frame(minWidth: windowSize.width, minHeight: windowSize.height)
                .colorScheme(Settings.appearance == .dark ? .dark : .light)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: windowSize.width, height: windowSize.height)
        .defaultPosition(.center)
        .commands {
            MenuBar(recentFilesManager: recentFilesManager, bookmarkManager: bookmarkManager, document: document)
        }

        SwiftUI.Settings {
            SettingsView()
                .environmentObject(fontManager)
                .environmentObject(document)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    private func removeUnwantedMenus() {
        // Wait until main menu is loaded
        DispatchQueue.main.async {
            guard let mainMenu = NSApp.mainMenu else { return }

            // Remove system Edit menu entirely
            if let editItem = mainMenu.item(withTitle: "Edit") {
                mainMenu.removeItem(editItem)
            }

            // Remove Show/Hide Tab Bar in Window menu
            if let windowMenu = mainMenu.item(withTitle: "Window")?.submenu {
                for item in windowMenu.items {
                    if item.title == "Show Tab Bar" || item.title == "Hide Tab Bar" {
                        windowMenu.removeItem(item)
                    }
                }
            }

            // Remove New Window / Close / Close All from File menu
            if let fileMenu = mainMenu.item(withTitle: "File")?.submenu {
                let unwantedTitles = ["New Window", "Close", "Close All"]
                for title in unwantedTitles {
                    if let item = fileMenu.items.first(where: { $0.title == title }) {
                        fileMenu.removeItem(item)
                    }
                }
            }
        }
    }
}
