//
//  HarryFanReaderApp.swift
//  harryfan-reader
//
//  Created by Vad Tymoshyk on 9/1/25.
//

import AppKit
import SwiftUI

// Extension for custom notification names
extension Notification.Name {
    static let openFileCommand = Notification.Name("AppCommand.openFile")
    static let openSearchCommand = Notification.Name("AppCommand.openSearch")
    static let findNextCommand = Notification.Name("AppCommand.findNext")
    static let findPreviousCommand = Notification.Name("AppCommand.findPrevious")
    static let addBookmarkCommand = Notification.Name("AppCommand.addBookmark")
    static let nextBookmarkCommand = Notification.Name("AppCommand.nextBookmark")
    static let previousBookmarkCommand = Notification.Name("AppCommand.previousBookmark")
    static let showBookmarksCommand = Notification.Name("AppCommand.showBookmarks")
}

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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(fontManager)
                .environmentObject(bookmarkManager)
                .frame(minWidth: 600, minHeight: 480)
                .colorScheme(AppSettings.appearance == .dark ? .dark : .light) // Apply the color scheme here based on AppSettings
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 800, height: 600)
        .defaultPosition(.center)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open") {
                    NotificationCenter.default.post(name: .openFileCommand, object: nil)
                }
            }
            CommandGroup(replacing: .appTermination) {
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q")
            }
            CommandMenu("Search") {
                Button("Find…") {
                    NotificationCenter.default.post(name: .openSearchCommand, object: nil)
                }
                .keyboardShortcut("f", modifiers: .command)
                Button("Find Next") {
                    NotificationCenter.default.post(name: .findNextCommand, object: nil)
                }
                .keyboardShortcut("g", modifiers: .command)
                Button("Find Previous") {
                    NotificationCenter.default.post(name: .findPreviousCommand, object: nil)
                }
                .keyboardShortcut("g", modifiers: [.command, .shift])
            }
            CommandMenu("Bookmarks") {
                Button("Add Bookmark") {
                    NotificationCenter.default.post(name: .addBookmarkCommand, object: nil)
                }
                .keyboardShortcut("b", modifiers: .command)
                Button("Next Bookmark") {
                    NotificationCenter.default.post(name: .nextBookmarkCommand, object: nil)
                }
                Button("Previous Bookmark") {
                    NotificationCenter.default.post(name: .previousBookmarkCommand, object: nil)
                }
                Divider()
                Button("Show Bookmarks") {
                    NotificationCenter.default.post(name: .showBookmarksCommand, object: nil)
                }
            }
            CommandMenu("Navigate") {
                Button("Scroll Up Line") {
                    NotificationCenter.default.post(name: .scrollUpCommand, object: nil)
                }
                .keyboardShortcut(.upArrow, modifiers: [])
                Button("Scroll Down Line") {
                    NotificationCenter.default.post(name: .scrollDownCommand, object: nil)
                }
                .keyboardShortcut(.downArrow, modifiers: [])
                Button("Scroll Up Page") {
                    NotificationCenter.default.post(name: .pageUpCommand, object: nil)
                }
                .keyboardShortcut(.upArrow, modifiers: .control)
                Button("Scroll Down Page") {
                    NotificationCenter.default.post(name: .pageDownCommand, object: nil)
                }
                .keyboardShortcut(.downArrow, modifiers: .control)
            }
        }

        Settings {
            SettingsView()
                .environmentObject(fontManager)
        }
    }
}
