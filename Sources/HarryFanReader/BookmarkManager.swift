//
//  BookmarkManager.swift
//  harryfan-reader
//
//  Created by @vt887 on 9/1/25.
//

import Foundation
import SwiftUI

// Manager for handling bookmarks in the app
class BookmarkManager: ObservableObject {
    // Published array of bookmarks
    @Published var bookmarks: [Bookmark] = []

    // Model for a single bookmark
    struct Bookmark: Identifiable, Codable {
        // Unique identifier for the bookmark
        let id: UUID
        // Name of the file the bookmark belongs to
        let fileName: String
        // Line number of the bookmark
        let line: Int
        // Description of the bookmark
        let description: String
        // Timestamp when the bookmark was created
        let timestamp: Date

        // Initialize a new bookmark
        init(fileName: String, line: Int, description: String) {
            id = UUID()
            self.fileName = fileName
            self.line = line
            self.description = description
            timestamp = Date()
        }
    }

    // Initialize the bookmark manager and load bookmarks
    init() {
        loadBookmarks()
    }

    // Add a new bookmark to the list
    func addBookmark(fileName: String, line: Int, description: String) {
        let bookmark = Bookmark(fileName: fileName, line: line, description: description)
        bookmarks.append(bookmark)
        saveBookmarks()
    }

    // Remove a bookmark from the list
    func removeBookmark(_ bookmark: Bookmark) {
        bookmarks.removeAll { $0.id == bookmark.id }
        saveBookmarks()
    }

    // Get all bookmarks for a specific file
    func getBookmarks(for fileName: String) -> [Bookmark] {
        bookmarks.filter { $0.fileName == fileName }
    }

    // Get the next bookmark after a given line in a file
    func nextBookmark(after line: Int, in fileName: String) -> Bookmark? {
        let fileBookmarks = getBookmarks(for: fileName).sorted { $0.line < $1.line }
        for bookmark in fileBookmarks where bookmark.line > line {
            return bookmark
        }
        return fileBookmarks.first
    }

    // Get the previous bookmark before a given line in a file
    func previousBookmark(before line: Int, in fileName: String) -> Bookmark? {
        let fileBookmarks = getBookmarks(for: fileName).sorted { $0.line < $1.line }
        for bookmark in fileBookmarks.reversed() where bookmark.line < line {
            return bookmark
        }
        return fileBookmarks.last
    }

    // Save bookmarks to persistent storage
    private func saveBookmarks() {
        if let data = try? JSONEncoder().encode(bookmarks) {
            UserDefaults.standard.set(data, forKey: "TxtViewerBookmarks")
        }
    }

    // Load bookmarks from persistent storage
    private func loadBookmarks() {
        if let data = UserDefaults.standard.data(forKey: "TxtViewerBookmarks"),
           let loadedBookmarks = try? JSONDecoder().decode([Bookmark].self, from: data)
        {
            bookmarks = loadedBookmarks
        }
    }
}
