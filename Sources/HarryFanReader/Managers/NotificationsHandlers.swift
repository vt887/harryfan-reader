//
//  NotificationsHandlers.swift
//  harryfan-reader
//
//  Created by @vt887 on 9/29/25.
//

import AppKit
import Combine
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

    @State private var subscriptions: Set<AnyCancellable> = []

    func body(content: Content) -> some View {
        let step1 = content
            .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { notification in
                if let window = notification.object as? NSWindow {
                    DebugLogger.log("NotificationsModifier: NSWindow didBecomeKeyNotification for window: \(window.title)")
                    overlayManager.addOverlay(.welcome)
                } else {
                    DebugLogger.log("NotificationsModifier: NSWindow didBecomeKeyNotification received")
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .openFileCommand)) { _ in showingFilePicker = true }
            .onReceive(NotificationCenter.default.publisher(for: .openRecentFileCommand)) { notification in
                if let userInfo = notification.userInfo, let url = userInfo["url"] as? URL {
                    document.openFile(at: url)
                    recentFilesManager.addRecentFile(url: url)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .clearRecentFilesCommand)) { _ in recentFilesManager.clearRecentFiles() }
            .onReceive(NotificationCenter.default.publisher(for: .toggleWordWrapCommand)) { _ in document.toggleWordWrap() }

        let step2 = step1
            .onReceive(NotificationCenter.default.publisher(for: .showHelpCommand)) { _ in
                NotificationCenter.default.post(name: .toggleHelpOverlay, object: nil)
            }
            .onReceive(NotificationCenter.default.publisher(for: .reloadFileCommand)) { _ in
                if let fileURL = document.fileURL {
                    document.openFile(at: fileURL)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .closeFileCommand)) { _ in
                document.closeFile()
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("AppCommand.print"))) { _ in
                let text = document.content.joined(separator: "\n")
                NotificationCenter.default.post(name: Notification.Name("AppCommand.printRequest"), object: nil, userInfo: ["text": text, "fileName": document.fileName])
            }

        let step3 = step2
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

        let step4 = step3
            .onReceive(NotificationCenter.default.publisher(for: .showAboutOverlay)) { _ in
                overlayManager.addOverlay(.about)
            }
            .onReceive(NotificationCenter.default.publisher(for: .showStatisticsOverlay)) { _ in
                overlayManager.addOverlay(.statistics)
            }
            .onReceive(NotificationCenter.default.publisher(for: .showLibraryOverlay)) { _ in
                overlayManager.addOverlay(.library)
            }
            .onReceive(NotificationCenter.default.publisher(for: .removeHelpOverlay)) { _ in
                overlayManager.removeHelpOverlay()
            }

        return step4
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
    static let showQuitOverlay = Notification.Name("showQuitOverlay")
    static let showStatisticsOverlay = Notification.Name("showStatisticsOverlay")
    static let showLibraryOverlay = Notification.Name("showLibraryOverlay")
}
