//
//  AppCommands.swift
//  harryfan-reader
//
//  Created by @vt887 on 9/29/25.
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
}

// Main app commands for menu and shortcuts
struct AppCommands: Commands {
    @ObservedObject var recentFilesManager: RecentFilesManager
    @ObservedObject var bookmarkManager: BookmarkManager
    @ObservedObject var document: TextDocument

    // Note: Bookmark and Recent Files menu items are generated inline in the Commands body to avoid parsing issues

    var body: some Commands {
        Group {
            CommandGroup(replacing: .newItem) {
                Button("Open...") {
                    NotificationCenter.default.post(name: .openFileCommand, object: nil)
                }
                .keyboardShortcut("o", modifiers: .command)

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

                // Print... moved from status bar into main AppCommands menu
                Button("Print...") {
                    DebugLogger.log("AppCommands: Print menu selected. document.totalLines=\(document.totalLines) fileName=\(document.fileName)")
                    DebugLogger.log("AppCommands: invoking PrintManager.sharedPrint")
                    DispatchQueue.main.async {
                        PrintManager.sharedPrint(document)
                    }
                    DebugLogger.log("AppCommands: invoked PrintManager.sharedPrint")
                }
                .keyboardShortcut("p", modifiers: .command)
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
}
