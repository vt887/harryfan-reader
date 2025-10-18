//
// NotificationsHandlers.swift
//  harryfan-reader
//
//  Created by @vt887 on 9/29/25.
//

import AppKit
import SwiftUI

// ViewModifier for handling app-wide notifications
private struct NotificationsModifier: ViewModifier {
    @ObservedObject var document: TextDocument
    @EnvironmentObject var fontManager: FontManager
    @EnvironmentObject var bookmarkManager: BookmarkManager
    @EnvironmentObject var recentFilesManager: RecentFilesManager
    @EnvironmentObject var overlayManager: OverlayManager
    @Binding var showingBookmarks: Bool
    @Binding var showingFilePicker: Bool

    func body(content: Content) -> some View {
        let contentWithWindow = content
            .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { notification in
                if let window = notification.object as? NSWindow {
                    DebugLogger.log("NotificationsModifier: NSWindow didBecomeKeyNotification for window: \(window.title)")
                    overlayManager.addOverlay(.welcome)
                } else {
                    DebugLogger.log("NotificationsModifier: NSWindow didBecomeKeyNotification received")
                }
            }

        let contentWithFile = contentWithWindow
            .onReceive(NotificationCenter.default.publisher(for: .openFileCommand)) { _ in showingFilePicker = true }
            .onReceive(NotificationCenter.default.publisher(for: .openRecentFileCommand)) { notification in
                if let userInfo = notification.userInfo, let url = userInfo["url"] as? URL {
                    document.openFile(at: url)
                    recentFilesManager.addRecentFile(url: url)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .clearRecentFilesCommand)) { _ in recentFilesManager.clearRecentFiles() }
            .onReceive(NotificationCenter.default.publisher(for: .toggleWordWrapCommand)) { _ in document.toggleWordWrap() }
            .onReceive(NotificationCenter.default.publisher(for: .showHelpCommand)) { _ in
                // Forward the command to the toggle notification so the view can
                // toggle the centered help overlay (show/hide).
                NotificationCenter.default.post(name: .toggleHelpOverlay, object: nil)
            }

        let contentWithBookmarks = contentWithFile
            .onReceive(NotificationCenter.default.publisher(for: .addBookmarkCommand)) { _ in
                guard !document.fileName.isEmpty else { return }
                let desc = document.getCurrentLine()
                bookmarkManager.addBookmark(fileName: document.fileName, line: document.currentLine, description: desc)
            }
            .onReceive(NotificationCenter.default.publisher(for: .nextBookmarkCommand)) { _ in
                guard !document.fileName.isEmpty else { return }
                if let bookmark = bookmarkManager.nextBookmark(after: document.currentLine, in: document.fileName) {
                    document.gotoLine(bookmark.line + 1)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .previousBookmarkCommand)) { _ in
                guard !document.fileName.isEmpty else { return }
                if let bookmark = bookmarkManager.previousBookmark(before: document.currentLine, in: document.fileName) {
                    document.gotoLine(bookmark.line + 1)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .showBookmarksCommand)) { _ in
                guard !document.fileName.isEmpty else { return }
                showingBookmarks = true
            }
            .onReceive(NotificationCenter.default.publisher(for: .openBookmarkCommand)) { notification in
                if let userInfo = notification.userInfo, let bookmark = userInfo["bookmark"] as? BookmarkManager.Bookmark {
                    document.gotoLine(bookmark.line + 1)
                }
            }

        let contentWithAbout = contentWithBookmarks
            .onReceive(NotificationCenter.default.publisher(for: .showAboutOverlay)) { _ in
                overlayManager.addOverlay(.about)
            }

        return contentWithAbout
            .onReceive(NotificationCenter.default.publisher(for: .removeHelpOverlay)) { _ in
                overlayManager.removeHelpOverlay()
            }
            .onReceive(NotificationCenter.default.publisher(for: .scrollUpCommand)) { _ in document.lineUp() }
            .onReceive(NotificationCenter.default.publisher(for: .scrollDownCommand)) { _ in document.lineDown() }
            .onReceive(NotificationCenter.default.publisher(for: .pageUpCommand)) { _ in document.pageUp() }
            .onReceive(NotificationCenter.default.publisher(for: .pageDownCommand)) { _ in document.pageDown() }
            .onReceive(NotificationCenter.default.publisher(for: .gotoStartCommand)) { _ in document.gotoStart() }
            .onReceive(NotificationCenter.default.publisher(for: .gotoEndCommand)) { _ in document.gotoEnd() }
    }
}

// Extension to apply notification handling to any view
extension View {
    func applyNotifications(document: TextDocument, showingBookmarks: Binding<Bool>, showingFilePicker: Binding<Bool>) -> some View {
        modifier(NotificationsModifier(document: document, showingBookmarks: showingBookmarks, showingFilePicker: showingFilePicker))
    }
}

extension Notification.Name {
    static let showAboutOverlay = Notification.Name("showAboutOverlay")
    static let showHelpOverlay = Notification.Name("showHelpOverlay")
    static let toggleHelpOverlay = Notification.Name("toggleHelpOverlay")
    static let removeHelpOverlay = Notification.Name("removeHelpOverlay")
}
