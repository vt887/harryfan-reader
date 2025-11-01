//
//  MenuBar.swift
//  harryfan-reader
//
//  Created by @vt887 on 10/26/25.
//

import AppKit
import SwiftUI

// Extension for custom notification names
extension Notification.Name {
    static let openFileCommand = Notification.Name("AppCommand.openFile")
    static let addBookmarkCommand = Notification.Name("AppCommand.addBookmark")
    static let nextBookmarkCommand = Notification.Name("AppCommand.nextBookmark")
    static let previousBookmarkCommand = Notification.Name("AppCommand.previousBookmark")
    static let showBookmarksCommand = Notification.Name("AppCommand.showBookmarks")
    static let scrollUpCommand = Notification.Name("scrollUpCommand")
    static let scrollDownCommand = Notification.Name("scrollDownCommand")
    static let pageUpCommand = Notification.Name("pageUpCommand")
    static let pageDownCommand = Notification.Name("pageDownCommand")
    static let gotoStartCommand = Notification.Name("gotoStartCommand")
    static let gotoEndCommand = Notification.Name("gotoEndCommand")
    static let openRecentFileCommand = Notification.Name("AppCommand.openRecentFile")
    static let openBookmarkCommand = Notification.Name("AppCommand.openBookmark")
    static let clearRecentFilesCommand = Notification.Name("clearRecentFilesCommand")
    static let toggleWordWrapCommand = Notification.Name("AppCommand.toggleWordWrap")
    static let showHelpCommand = Notification.Name("AppCommand.showHelp")
    static let reloadFileCommand = Notification.Name("AppCommand.reloadFile")
    static let closeFileCommand = Notification.Name("AppCommand.closeFile")
}

// Main app commands for menu and shortcuts (exposed as `MenuBar`)
struct MenuBar: Commands {
    @ObservedObject var recentFilesManager: RecentFilesManager
    @ObservedObject var bookmarkManager: BookmarkManager
    @ObservedObject var document: TextDocument

    // Note: Bookmark and Recent Files menu items are generated inline in the Commands body to avoid parsing issues

    var body: some Commands {
        CommandGroup(replacing: .undoRedo) {}
        CommandGroup(replacing: .pasteboard) {}

        CommandGroup(replacing: .newItem) {
            Button("Open...") {
                NotificationCenter.default.post(name: .openFileCommand, object: nil)
            }
            .keyboardShortcut("o", modifiers: [.command, .shift])

            Button("Re-read File") {
                DebugLogger.log("MenuBar: Reload menu selected")
                NotificationCenter.default.post(name: .reloadFileCommand, object: nil)
            }
            .keyboardShortcut("r", modifiers: .command)
            .disabled(document.totalLines == 0 && document.fileName.isEmpty)

            Menu("Recent Files") {
                if recentFilesManager.recentFiles.isEmpty {
                    Text("No Recent Files").disabled(true)
                } else {
                    ForEach(recentFilesManager.recentFiles.indices, id: \.self) { idx in
                        Button(recentFilesManager.recentFiles[idx].displayName) {
                            NotificationCenter.default.post(name: .openRecentFileCommand, object: nil, userInfo: ["url": recentFilesManager.recentFiles[idx].url])
                        }
                    }
                    Divider()
                    Button("Clear Recent") { NotificationCenter.default.post(name: .clearRecentFilesCommand, object: nil) }
                }
            }

            Divider()
            Button("Print File") {
                DebugLogger.log("MenuBar: Print menu selected. document.totalLines=\(document.totalLines) fileName=\(document.fileName)")
                let text = document.content.joined(separator: "\n")
                NotificationCenter.default.post(name: Notification.Name("AppCommand.printRequest"), object: nil, userInfo: ["text": text, "fileName": document.fileName])
            }
            .keyboardShortcut("p", modifiers: .command)
            .disabled(document.totalLines == 0 && document.fileName.isEmpty)

            Button("Statistics") {
                NotificationCenter.default.post(name: .showStatisticsOverlay, object: nil)
            }
            .keyboardShortcut("S", modifiers: [.command, .shift])
            .disabled(document.totalLines == 0 && document.fileName.isEmpty)
        }

        CommandMenu("Bookmarks") {
            Button("Add Bookmark") {
                NotificationCenter.default.post(name: .addBookmarkCommand, object: nil)
            }
            .keyboardShortcut("b", modifiers: .command)

            Divider()

            Menu("Bookmarks") {
                if bookmarkManager.bookmarks.isEmpty {
                    Text("No Bookmarks").disabled(true)
                } else {
                    ForEach(bookmarkManager.bookmarks.indices, id: \.self) { idx in
                        Button("\(bookmarkManager.bookmarks[idx].fileName): Line \(bookmarkManager.bookmarks[idx].line + 1)") {
                            NotificationCenter.default.post(name: .openBookmarkCommand, object: nil, userInfo: ["bookmark": bookmarkManager.bookmarks[idx]])
                        }
                    }
                }
            }
        }
        // Library menu (separate from File)
        CommandMenu("Library") {
            Button("Login") {
                DebugLogger.log("MenuBar: Library -> Login selected")
                NotificationCenter.default.post(name: .showLibraryOverlay, object: nil, userInfo: ["action": "login"])
            }
            Button("Browse") {
                DebugLogger.log("MenuBar: Library -> Browse selected")
                NotificationCenter.default.post(name: .showLibraryOverlay, object: nil, userInfo: ["action": "browse"])
            }
        }
        CommandMenu("Navigation") {
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
            .keyboardShortcut(.upArrow, modifiers: .command)
            Button("Scroll Down Page") {
                NotificationCenter.default.post(name: .pageDownCommand, object: nil)
            }
            .keyboardShortcut(.downArrow, modifiers: .command)
            Divider()
            Button("Go to Start") {
                NotificationCenter.default.post(name: .gotoStartCommand, object: nil)
            }
            .keyboardShortcut(.upArrow, modifiers: [.command, .control])
            Button("Go to End") {
                NotificationCenter.default.post(name: .gotoEndCommand, object: nil)
            }
            .keyboardShortcut(.downArrow, modifiers: [.command, .control])
        }
    }
}
