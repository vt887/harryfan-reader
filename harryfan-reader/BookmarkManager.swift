//
//  BookmarkManager.swift
//  harryfan-reader
//
//  Created by Vad Tymoshyk on 9/1/25.
//

import Foundation
import SwiftUI

class BookmarkManager: ObservableObject {
    @Published var bookmarks: [Bookmark] = []

    struct Bookmark: Identifiable, Codable {
        let id: UUID
        let fileName: String
        let line: Int
        let description: String
        let timestamp: Date

        init(fileName: String, line: Int, description: String) {
            id = UUID()
            self.fileName = fileName
            self.line = line
            self.description = description
            timestamp = Date()
        }
    }

    init() {
        loadBookmarks()
    }

    func addBookmark(fileName: String, line: Int, description: String) {
        let bookmark = Bookmark(fileName: fileName, line: line, description: description)
        bookmarks.append(bookmark)
        saveBookmarks()
    }

    func removeBookmark(_ bookmark: Bookmark) {
        bookmarks.removeAll { $0.id == bookmark.id }
        saveBookmarks()
    }

    func getBookmarks(for fileName: String) -> [Bookmark] {
        bookmarks.filter { $0.fileName == fileName }
    }

    func nextBookmark(after line: Int, in fileName: String) -> Bookmark? {
        let fileBookmarks = getBookmarks(for: fileName).sorted { $0.line < $1.line }
        for bookmark in fileBookmarks where bookmark.line > line {
            return bookmark
        }
        return fileBookmarks.first
    }

    func previousBookmark(before line: Int, in fileName: String) -> Bookmark? {
        let fileBookmarks = getBookmarks(for: fileName).sorted { $0.line < $1.line }
        for bookmark in fileBookmarks.reversed() where bookmark.line < line {
            return bookmark
        }
        return fileBookmarks.last
    }

    private func saveBookmarks() {
        if let data = try? JSONEncoder().encode(bookmarks) {
            UserDefaults.standard.set(data, forKey: "TxtViewerBookmarks")
        }
    }

    private func loadBookmarks() {
        if let data = UserDefaults.standard.data(forKey: "TxtViewerBookmarks"),
           let loadedBookmarks = try? JSONDecoder().decode([Bookmark].self, from: data)
        {
            bookmarks = loadedBookmarks
        }
    }
}
