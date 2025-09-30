//
// NotificationsHandlers.swift
//  harryfan-reader
//
//  Created by @vt887 on 9/29/25.
//

import AppKit
import SwiftUI

private struct NotificationsModifier: ViewModifier {
    @ObservedObject var document: TextDocument
    @EnvironmentObject var fontManager: FontManager
    @EnvironmentObject var bookmarkManager: BookmarkManager
    @EnvironmentObject var recentFilesManager: RecentFilesManager
    @Binding var showingSearch: Bool
    @Binding var showingBookmarks: Bool
    @Binding var showingFilePicker: Bool
    @Binding var lastSearchTerm: String

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in }
            .onReceive(NotificationCenter.default.publisher(for: .openFileCommand)) { _ in showingFilePicker = true }
            .onReceive(NotificationCenter.default.publisher(for: .openSearchCommand)) { _ in if document.fileName.isEmpty { return }; showingSearch = true }
            .onReceive(NotificationCenter.default.publisher(for: .findNextCommand)) { _ in guard !lastSearchTerm.isEmpty else { showingSearch = true; return }; if let idx = document.search(lastSearchTerm, direction: .forward) { document.gotoLine(idx + 1) } }
            .onReceive(NotificationCenter.default.publisher(for: .findPreviousCommand)) { _ in guard !lastSearchTerm.isEmpty else { showingSearch = true; return }; if let idx = document.search(lastSearchTerm, direction: .backward) { document.gotoLine(idx + 1) } }
            .onReceive(NotificationCenter.default.publisher(for: .addBookmarkCommand)) { _ in guard !document.fileName.isEmpty else { return }; let desc = document.getCurrentLine(); bookmarkManager.addBookmark(fileName: document.fileName, line: document.currentLine, description: desc) }
            .onReceive(NotificationCenter.default.publisher(for: .nextBookmarkCommand)) { _ in guard !document.fileName.isEmpty else { return }; if let bookmark = bookmarkManager.nextBookmark(after: document.currentLine, in: document.fileName) { document.gotoLine(bookmark.line + 1) } }
            .onReceive(NotificationCenter.default.publisher(for: .previousBookmarkCommand)) { _ in guard !document.fileName.isEmpty else { return }; if let bookmark = bookmarkManager.previousBookmark(before: document.currentLine, in: document.fileName) { document.gotoLine(bookmark.line + 1) } }
            .onReceive(NotificationCenter.default.publisher(for: .showBookmarksCommand)) { _ in guard !document.fileName.isEmpty else { return }; showingBookmarks = true }
            .onReceive(NotificationCenter.default.publisher(for: .scrollUpCommand)) { _ in document.gotoStart() }
            .onReceive(NotificationCenter.default.publisher(for: .scrollDownCommand)) { _ in document.gotoEnd() }
            .onReceive(NotificationCenter.default.publisher(for: .pageUpCommand)) { _ in document.pageUp() }
            .onReceive(NotificationCenter.default.publisher(for: .pageDownCommand)) { _ in document.pageDown() }
            .onReceive(NotificationCenter.default.publisher(for: .openRecentFileCommand)) { notification in if let userInfo = notification.userInfo, let url = userInfo["url"] as? URL { document.openFile(at: url); recentFilesManager.addRecentFile(url: url) } }
            .onReceive(NotificationCenter.default.publisher(for: .clearRecentFilesCommand)) { _ in recentFilesManager.clearRecentFiles() }
            .onReceive(NotificationCenter.default.publisher(for: .openBookmarkCommand)) { notification in if let userInfo = notification.userInfo, let bookmark = userInfo["bookmark"] as? BookmarkManager.Bookmark { if document.fileName != bookmark.fileName { document.gotoLine(bookmark.line + 1) } else { document.gotoLine(bookmark.line + 1) } } }
    }
}

extension View {
    func applyNotifications(document: TextDocument, showingSearch: Binding<Bool>, showingBookmarks: Binding<Bool>, showingFilePicker: Binding<Bool>, lastSearchTerm: Binding<String>) -> some View {
        modifier(NotificationsModifier(document: document, showingSearch: showingSearch, showingBookmarks: showingBookmarks, showingFilePicker: showingFilePicker, lastSearchTerm: lastSearchTerm))
    }
}
