//
//  BookmarkManagerTests.swift
//  HarryFanReaderTests
//
//  Created by @vt887 on 9/29/25.
//

@testable import HarryFan_Reader
import XCTest

final class BookmarkManagerTests: XCTestCase {
    var bookmarkManager: BookmarkManager!

    override func setUp() {
        super.setUp()
        // Clear any existing bookmarks from UserDefaults for clean testing
        UserDefaults.standard.removeObject(forKey: "TxtViewerBookmarks")
        bookmarkManager = BookmarkManager()
    }

    override func tearDown() {
        // Clean up UserDefaults after each test
        UserDefaults.standard.removeObject(forKey: "TxtViewerBookmarks")
        bookmarkManager = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialState() {
        XCTAssertEqual(bookmarkManager.bookmarks.count, 0)
    }

    // MARK: - Bookmark Creation Tests

    func testAddBookmark() {
        bookmarkManager.addBookmark(fileName: "test.txt", line: 10, description: "Important line")

        XCTAssertEqual(bookmarkManager.bookmarks.count, 1)

        let bookmark = bookmarkManager.bookmarks.first!
        XCTAssertEqual(bookmark.fileName, "test.txt")
        XCTAssertEqual(bookmark.line, 10)
        XCTAssertEqual(bookmark.description, "Important line")
        XCTAssertNotNil(bookmark.id)
        XCTAssertNotNil(bookmark.timestamp)
    }

    func testAddMultipleBookmarks() {
        bookmarkManager.addBookmark(fileName: "file1.txt", line: 5, description: "First bookmark")
        bookmarkManager.addBookmark(fileName: "file1.txt", line: 15, description: "Second bookmark")
        bookmarkManager.addBookmark(fileName: "file2.txt", line: 20, description: "Third bookmark")

        XCTAssertEqual(bookmarkManager.bookmarks.count, 3)

        // Verify each bookmark has unique ID
        let ids = bookmarkManager.bookmarks.map(\.id)
        let uniqueIds = Set(ids)
        XCTAssertEqual(ids.count, uniqueIds.count)
    }

    // MARK: - Bookmark Removal Tests

    func testRemoveBookmark() {
        bookmarkManager.addBookmark(fileName: "test.txt", line: 10, description: "To be removed")
        bookmarkManager.addBookmark(fileName: "test.txt", line: 20, description: "To be kept")

        XCTAssertEqual(bookmarkManager.bookmarks.count, 2)

        let bookmarkToRemove = bookmarkManager.bookmarks.first!
        bookmarkManager.removeBookmark(bookmarkToRemove)

        XCTAssertEqual(bookmarkManager.bookmarks.count, 1)
        XCTAssertEqual(bookmarkManager.bookmarks.first?.description, "To be kept")
    }

    func testRemoveNonexistentBookmark() {
        bookmarkManager.addBookmark(fileName: "test.txt", line: 10, description: "Existing bookmark")

        // Create a bookmark that doesn't exist in the manager
        let nonexistentBookmark = BookmarkManager.Bookmark(fileName: "other.txt", line: 5, description: "Nonexistent")

        XCTAssertEqual(bookmarkManager.bookmarks.count, 1)
        bookmarkManager.removeBookmark(nonexistentBookmark)
        XCTAssertEqual(bookmarkManager.bookmarks.count, 1) // Should remain unchanged
    }

    // MARK: - Bookmark Filtering Tests

    func testGetBookmarksForFile() {
        bookmarkManager.addBookmark(fileName: "file1.txt", line: 10, description: "File1 bookmark 1")
        bookmarkManager.addBookmark(fileName: "file2.txt", line: 15, description: "File2 bookmark")
        bookmarkManager.addBookmark(fileName: "file1.txt", line: 20, description: "File1 bookmark 2")

        let file1Bookmarks = bookmarkManager.getBookmarks(for: "file1.txt")
        let file2Bookmarks = bookmarkManager.getBookmarks(for: "file2.txt")
        let nonexistentFileBookmarks = bookmarkManager.getBookmarks(for: "nonexistent.txt")

        XCTAssertEqual(file1Bookmarks.count, 2)
        XCTAssertEqual(file2Bookmarks.count, 1)
        XCTAssertEqual(nonexistentFileBookmarks.count, 0)

        XCTAssertTrue(file1Bookmarks.allSatisfy { $0.fileName == "file1.txt" })
        XCTAssertTrue(file2Bookmarks.allSatisfy { $0.fileName == "file2.txt" })
    }

    // MARK: - Bookmark Navigation Tests

    func testNextBookmarkAfter() {
        bookmarkManager.addBookmark(fileName: "test.txt", line: 10, description: "Bookmark 1")
        bookmarkManager.addBookmark(fileName: "test.txt", line: 30, description: "Bookmark 2")
        bookmarkManager.addBookmark(fileName: "test.txt", line: 20, description: "Bookmark 3")
        bookmarkManager.addBookmark(fileName: "other.txt", line: 15, description: "Other file bookmark")

        // Test finding next bookmark after line 15
        let nextBookmark = bookmarkManager.nextBookmark(after: 15, in: "test.txt")
        XCTAssertNotNil(nextBookmark)
        XCTAssertEqual(nextBookmark?.line, 20) // Should find the bookmark at line 20

        // Test finding next bookmark after line 25 (should find line 30)
        let nextAfter25 = bookmarkManager.nextBookmark(after: 25, in: "test.txt")
        XCTAssertNotNil(nextAfter25)
        XCTAssertEqual(nextAfter25?.line, 30) // Should find bookmark at line 30

        // Test wrapping to first bookmark when searching after the last bookmark
        let wrappedBookmark = bookmarkManager.nextBookmark(after: 35, in: "test.txt")
        XCTAssertNotNil(wrappedBookmark)
        XCTAssertEqual(wrappedBookmark?.line, 10) // Should wrap to first bookmark

        // Test with no bookmarks in file
        let noBookmark = bookmarkManager.nextBookmark(after: 5, in: "nonexistent.txt")
        XCTAssertNil(noBookmark)
    }

    func testPreviousBookmarkBefore() {
        bookmarkManager.addBookmark(fileName: "test.txt", line: 10, description: "Bookmark 1")
        bookmarkManager.addBookmark(fileName: "test.txt", line: 30, description: "Bookmark 2")
        bookmarkManager.addBookmark(fileName: "test.txt", line: 20, description: "Bookmark 3")
        bookmarkManager.addBookmark(fileName: "other.txt", line: 15, description: "Other file bookmark")

        // Test finding previous bookmark before line 25
        let prevBookmark = bookmarkManager.previousBookmark(before: 25, in: "test.txt")
        XCTAssertNotNil(prevBookmark)
        XCTAssertEqual(prevBookmark?.line, 20) // Should find the bookmark at line 20

        // Test finding previous bookmark before line 5 (should wrap to last)
        let wrappedBookmark = bookmarkManager.previousBookmark(before: 5, in: "test.txt")
        XCTAssertNotNil(wrappedBookmark)
        XCTAssertEqual(wrappedBookmark?.line, 30) // Should wrap to last bookmark

        // Test with no bookmarks in file
        let noBookmark = bookmarkManager.previousBookmark(before: 25, in: "nonexistent.txt")
        XCTAssertNil(noBookmark)
    }

    func testNextBookmarkWithSingleBookmark() {
        bookmarkManager.addBookmark(fileName: "test.txt", line: 15, description: "Only bookmark")

        let nextBookmark = bookmarkManager.nextBookmark(after: 10, in: "test.txt")
        XCTAssertNotNil(nextBookmark)
        XCTAssertEqual(nextBookmark?.line, 15)

        let wrappedBookmark = bookmarkManager.nextBookmark(after: 20, in: "test.txt")
        XCTAssertNotNil(wrappedBookmark)
        XCTAssertEqual(wrappedBookmark?.line, 15) // Should wrap to the same bookmark
    }

    func testPreviousBookmarkWithSingleBookmark() {
        bookmarkManager.addBookmark(fileName: "test.txt", line: 15, description: "Only bookmark")

        let prevBookmark = bookmarkManager.previousBookmark(before: 20, in: "test.txt")
        XCTAssertNotNil(prevBookmark)
        XCTAssertEqual(prevBookmark?.line, 15)

        let wrappedBookmark = bookmarkManager.previousBookmark(before: 10, in: "test.txt")
        XCTAssertNotNil(wrappedBookmark)
        XCTAssertEqual(wrappedBookmark?.line, 15) // Should wrap to the same bookmark
    }

    // MARK: - Persistence Tests

    func testBookmarkPersistence() {
        // Add bookmarks
        bookmarkManager.addBookmark(fileName: "test.txt", line: 10, description: "Persistent bookmark 1")
        bookmarkManager.addBookmark(fileName: "test.txt", line: 20, description: "Persistent bookmark 2")

        XCTAssertEqual(bookmarkManager.bookmarks.count, 2)

        // Create a new bookmark manager (simulating app restart)
        let newBookmarkManager = BookmarkManager()

        // Verify bookmarks were loaded from persistence
        XCTAssertEqual(newBookmarkManager.bookmarks.count, 2)

        let loadedBookmarks = newBookmarkManager.bookmarks.sorted { $0.line < $1.line }
        XCTAssertEqual(loadedBookmarks[0].fileName, "test.txt")
        XCTAssertEqual(loadedBookmarks[0].line, 10)
        XCTAssertEqual(loadedBookmarks[0].description, "Persistent bookmark 1")
        XCTAssertEqual(loadedBookmarks[1].line, 20)
        XCTAssertEqual(loadedBookmarks[1].description, "Persistent bookmark 2")
    }

    func testBookmarkRemovalPersistence() {
        // Add bookmarks
        bookmarkManager.addBookmark(fileName: "test.txt", line: 10, description: "To be removed")
        bookmarkManager.addBookmark(fileName: "test.txt", line: 20, description: "To be kept")

        // Remove one bookmark
        let bookmarkToRemove = bookmarkManager.bookmarks.first { $0.line == 10 }!
        bookmarkManager.removeBookmark(bookmarkToRemove)

        // Create a new bookmark manager (simulating app restart)
        let newBookmarkManager = BookmarkManager()

        // Verify only the remaining bookmark was loaded
        XCTAssertEqual(newBookmarkManager.bookmarks.count, 1)
        XCTAssertEqual(newBookmarkManager.bookmarks.first?.line, 20)
        XCTAssertEqual(newBookmarkManager.bookmarks.first?.description, "To be kept")
    }

    // MARK: - Bookmark Model Tests

    func testBookmarkInitialization() {
        let bookmark = BookmarkManager.Bookmark(fileName: "test.txt", line: 42, description: "Test bookmark")

        XCTAssertNotNil(bookmark.id)
        XCTAssertEqual(bookmark.fileName, "test.txt")
        XCTAssertEqual(bookmark.line, 42)
        XCTAssertEqual(bookmark.description, "Test bookmark")
        XCTAssertNotNil(bookmark.timestamp)

        // Verify timestamp is recent (within last second)
        let now = Date()
        XCTAssertLessThan(abs(bookmark.timestamp.timeIntervalSince(now)), 1.0)
    }

    func testBookmarkIdentifiability() {
        let bookmark1 = BookmarkManager.Bookmark(fileName: "test.txt", line: 10, description: "Bookmark 1")
        let bookmark2 = BookmarkManager.Bookmark(fileName: "test.txt", line: 10, description: "Bookmark 2")

        XCTAssertNotEqual(bookmark1.id, bookmark2.id) // Each bookmark should have unique ID
    }

    // MARK: - Edge Cases

    func testBookmarkWithEmptyDescription() {
        bookmarkManager.addBookmark(fileName: "test.txt", line: 10, description: "")

        XCTAssertEqual(bookmarkManager.bookmarks.count, 1)
        XCTAssertEqual(bookmarkManager.bookmarks.first?.description, "")
    }

    func testBookmarkWithZeroLine() {
        bookmarkManager.addBookmark(fileName: "test.txt", line: 0, description: "First line bookmark")

        XCTAssertEqual(bookmarkManager.bookmarks.count, 1)
        XCTAssertEqual(bookmarkManager.bookmarks.first?.line, 0)
    }

    func testBookmarkWithNegativeLine() {
        bookmarkManager.addBookmark(fileName: "test.txt", line: -5, description: "Negative line bookmark")

        XCTAssertEqual(bookmarkManager.bookmarks.count, 1)
        XCTAssertEqual(bookmarkManager.bookmarks.first?.line, -5) // Should allow negative lines
    }
}
