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
    static let openSearchCommand = Notification.Name("AppCommand.openSearch")
    static let findNextCommand = Notification.Name("AppCommand.findNext")
    static let findPreviousCommand = Notification.Name("AppCommand.findPrevious")
    static let addBookmarkCommand = Notification.Name("AppCommand.addBookmark")
    static let nextBookmarkCommand = Notification.Name("AppCommand.nextBookmark")
    static let previousBookmarkCommand = Notification.Name("AppCommand.previousBookmark")
    static let showBookmarksCommand = Notification.Name("AppCommand.showBookmarks")
    static let scrollUpCommand = Notification.Name("scrollUpCommand")
    static let scrollDownCommand = Notification.Name("scrollDownCommand")
    static let pageUpCommand = Notification.Name("pageUpCommand")
    static let pageDownCommand = Notification.Name("pageDownCommand")
    static let scrollToStartCommand = Notification.Name("scrollToStartCommand")
    static let scrollToEndCommand = Notification.Name("scrollToEndCommand")
    static let openRecentFileCommand = Notification.Name("AppCommand.openRecentFile")
    static let openBookmarkCommand = Notification.Name("AppCommand.openBookmark")
    static let clearRecentFilesCommand = Notification.Name("clearRecentFilesCommand")
}

struct AppCommands: Commands {
    @ObservedObject var recentFilesManager: RecentFilesManager
    @ObservedObject var bookmarkManager: BookmarkManager

    var body: some Commands {
        Group {
            CommandGroup(replacing: .newItem) {
                Button("Open...") {
                    NotificationCenter.default.post(name: .openFileCommand, object: nil)
                }
                .keyboardShortcut("o", modifiers: .command)

                Menu("Recent Files") {
                    if recentFilesManager.recentFiles.isEmpty {
                        Text("No Recent Files")
                            .disabled(true)
                    } else {
                        ForEach(recentFilesManager.recentFiles) { file in
                            Button(file.displayName) {
                                NotificationCenter.default.post(
                                    name: .openRecentFileCommand,
                                    object: nil,
                                    userInfo: ["url": file.url]
                                )
                            }
                        }

                        Divider()

                        Button("Clear Recent") {
                            NotificationCenter.default.post(name: .clearRecentFilesCommand, object: nil)
                        }
                    }
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

                Divider()

                Menu("Bookmarks") {
                    let allBookmarks = bookmarkManager.bookmarks

                    if allBookmarks.isEmpty {
                        Text("No Bookmarks")
                            .disabled(true)
                    } else {
                        ForEach(allBookmarks) { bookmark in
                            Button("\(bookmark.fileName): Line \(bookmark.line + 1)") {
                                NotificationCenter.default.post(
                                    name: .openBookmarkCommand,
                                    object: nil,
                                    userInfo: ["bookmark": bookmark]
                                )
                            }
                        }
                    }
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
                Divider()
                Button("Scroll to start") {
                    NotificationCenter.default.post(name: .scrollToStartCommand, object: nil)
                }
                .keyboardShortcut(.home, modifiers: [])
                Button("Scroll to end") {
                    NotificationCenter.default.post(name: .scrollToEndCommand, object: nil)
                }
                .keyboardShortcut(.end, modifiers: [])
            }
        }
    }
}
