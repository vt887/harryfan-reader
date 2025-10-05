//
//  BookmarkManagerQuickSpec.swift
//  HarryFanReaderTests
//
//  Created by @vt887 on 9/29/25.
//

import Foundation
@testable import HarryFanReader
import Nimble
import Quick

final class BookmarkManagerQuickSpec: QuickSpec {
    override class func spec() {
        var bookmarkManager: BookmarkManager!
        let key = "\(AppSettings.appName)Bookmarks"
        let testFileName = "test.txt"
        let otherFileName = "other.txt"
        let keptDescription = "To be kept"
        let removedDescription = "To be removed"

        beforeEach {
            UserDefaults.standard.removeObject(forKey: key)
            bookmarkManager = BookmarkManager()
        }
        afterEach {
            UserDefaults.standard.removeObject(forKey: key)
            bookmarkManager = nil
        }

        describe("BookmarkManager") {
            context("initial state") {
                // Checks that the bookmark manager starts with no bookmarks.
                it("starts with no bookmarks") {
                    expect(bookmarkManager.bookmarks.count).to(equal(0))
                }
            }
            context("adding a bookmark") {
                // Checks that adding a bookmark works and fields are set correctly.
                it("adds a bookmark correctly") {
                    bookmarkManager.addBookmark(fileName: testFileName, line: 10, description: "Important line")
                    expect(bookmarkManager.bookmarks.count).to(equal(1))
                    let bookmark = bookmarkManager.bookmarks.first
                    expect(bookmark?.fileName).to(equal(testFileName))
                    expect(bookmark?.line).to(equal(10))
                    expect(bookmark?.description).to(equal("Important line"))
                    expect(bookmark?.id).toNot(beNil())
                    expect(bookmark?.timestamp).toNot(beNil())
                }
            }
            context("adding multiple bookmarks") {
                // Checks that multiple bookmarks can be added and IDs are unique.
                it("adds multiple bookmarks correctly") {
                    bookmarkManager.addBookmark(fileName: testFileName, line: 5, description: "Bookmark 1")
                    bookmarkManager.addBookmark(fileName: testFileName, line: 15, description: "Bookmark 2")
                    bookmarkManager.addBookmark(fileName: testFileName, line: 20, description: "Bookmark 3")

                    expect(bookmarkManager.bookmarks.count).to(equal(3))

                    // Verify each bookmark has unique ID
                    let ids = bookmarkManager.bookmarks.map(\.id)
                    let uniqueIds = Set(ids)
                    expect(ids.count).to(equal(uniqueIds.count))
                }
            }
            context("removing a bookmark") {
                // Checks that removing a bookmark works and only the correct one is removed.
                it("removes the correct bookmark") {
                    bookmarkManager.addBookmark(fileName: testFileName, line: 10, description: removedDescription)
                    bookmarkManager.addBookmark(fileName: testFileName, line: 20, description: keptDescription)

                    expect(bookmarkManager.bookmarks.count).to(equal(2))

                    let bookmarkToRemove = bookmarkManager.bookmarks.first!
                    bookmarkManager.removeBookmark(bookmarkToRemove)

                    expect(bookmarkManager.bookmarks.count).to(equal(1))
                    expect(bookmarkManager.bookmarks.first?.description).to(equal(keptDescription))
                }
                // Checks that removing a nonexistent bookmark does not affect the list.
                it("does nothing when removing a nonexistent bookmark") {
                    bookmarkManager.addBookmark(fileName: testFileName, line: 10, description: "Bookmark 99")

                    // Create a bookmark that doesn't exist in the manager
                    let nonexistentBookmark = BookmarkManager.Bookmark(fileName: otherFileName, line: 5, description: "Nonexistent")

                    expect(bookmarkManager.bookmarks.count).to(equal(1))
                    bookmarkManager.removeBookmark(nonexistentBookmark)
                    expect(bookmarkManager.bookmarks.count).to(equal(1)) // Should remain unchanged
                }
            }
            context("filtering bookmarks") {
                // Checks that bookmarks can be filtered by file name.
                it("gets bookmarks for a specific file") {
                    bookmarkManager.addBookmark(fileName: testFileName, line: 10, description: "File1 bookmark")
                    bookmarkManager.addBookmark(fileName: testFileName, line: 15, description: "File2 bookmark")
                    bookmarkManager.addBookmark(fileName: testFileName, line: 20, description: "File1 bookmark")

                    let file1Bookmarks = bookmarkManager.getBookmarks(for: testFileName)
                    let file2Bookmarks = bookmarkManager.getBookmarks(for: testFileName)
                    let nonexistentFileBookmarks = bookmarkManager.getBookmarks(for: otherFileName)

                    expect(file1Bookmarks.count).to(equal(3))
                    expect(file2Bookmarks.count).to(equal(3))
                    expect(nonexistentFileBookmarks.count).to(equal(0))

                    expect(file1Bookmarks.allSatisfy { $0.fileName == testFileName }).to(beTrue())
                    expect(file2Bookmarks.allSatisfy { $0.fileName == testFileName }).to(beTrue())
                }
            }
            context("navigating bookmarks") {
                // Checks that nextBookmark finds the correct next bookmark.
                it("finds the next bookmark correctly") {
                    bookmarkManager.addBookmark(fileName: testFileName, line: 10, description: "Bookmark 1")
                    bookmarkManager.addBookmark(fileName: testFileName, line: 30, description: "Bookmark 2")
                    bookmarkManager.addBookmark(fileName: testFileName, line: 20, description: "Bookmark 3")
                    bookmarkManager.addBookmark(fileName: otherFileName, line: 15, description: "Other file bookmark")

                    // Test finding next bookmark after line 15
                    let nextBookmark = bookmarkManager.nextBookmark(after: 15, in: testFileName)
                    expect(nextBookmark).toNot(beNil())
                    expect(nextBookmark?.line).to(equal(20)) // Should find the bookmark at line 20

                    // Test finding next bookmark after line 25 (should find line 30)
                    let nextAfter25 = bookmarkManager.nextBookmark(after: 25, in: testFileName)
                    expect(nextAfter25).toNot(beNil())
                    expect(nextAfter25?.line).to(equal(30)) // Should find bookmark at line 30

                    // Test wrapping to first bookmark when searching after the last bookmark
                    let wrappedBookmark = bookmarkManager.nextBookmark(after: 35, in: testFileName)
                    expect(wrappedBookmark).toNot(beNil())
                    expect(wrappedBookmark?.line).to(equal(10)) // Should wrap to first bookmark

                    // Test with no bookmarks in file
                    let noBookmark = bookmarkManager.nextBookmark(after: 5, in: "nonexistent.txt")
                    expect(noBookmark).to(beNil())
                }
                // Checks that previousBookmark finds the correct previous bookmark.
                it("finds the previous bookmark correctly") {
                    bookmarkManager.addBookmark(fileName: testFileName, line: 10, description: "Bookmark 1")
                    bookmarkManager.addBookmark(fileName: testFileName, line: 30, description: "Bookmark 2")
                    bookmarkManager.addBookmark(fileName: testFileName, line: 20, description: "Bookmark 3")
                    bookmarkManager.addBookmark(fileName: otherFileName, line: 15, description: "Other file bookmark")

                    // Test finding previous bookmark before line 25
                    let prevBookmark = bookmarkManager.previousBookmark(before: 25, in: testFileName)
                    expect(prevBookmark).toNot(beNil())
                    expect(prevBookmark?.line).to(equal(20)) // Should find the bookmark at line 20

                    // Test finding previous bookmark before line 5 (should wrap to last)
                    let wrappedBookmark = bookmarkManager.previousBookmark(before: 5, in: testFileName)
                    expect(wrappedBookmark).toNot(beNil())
                    expect(wrappedBookmark?.line).to(equal(30)) // Should wrap to last bookmark

                    // Test with no bookmarks in file
                    let noBookmark = bookmarkManager.previousBookmark(before: 25, in: "nonexistent.txt")
                    expect(noBookmark).to(beNil())
                }
                // Checks navigation when only one bookmark exists.
                it("handles single bookmark navigation correctly") {
                    bookmarkManager.addBookmark(fileName: testFileName, line: 15, description: "Only bookmark")

                    let nextBookmark = bookmarkManager.nextBookmark(after: 10, in: testFileName)
                    expect(nextBookmark).toNot(beNil())
                    expect(nextBookmark?.line).to(equal(15))

                    let wrappedBookmark = bookmarkManager.nextBookmark(after: 20, in: testFileName)
                    expect(wrappedBookmark).toNot(beNil())
                    expect(wrappedBookmark?.line).to(equal(15)) // Should wrap to the same bookmark

                    let prevBookmark = bookmarkManager.previousBookmark(before: 20, in: testFileName)
                    expect(prevBookmark).toNot(beNil())
                    expect(prevBookmark?.line).to(equal(15))

                    let wrappedPrevBookmark = bookmarkManager.previousBookmark(before: 10, in: testFileName)
                    expect(wrappedPrevBookmark).toNot(beNil())
                    expect(wrappedPrevBookmark?.line).to(equal(15)) // Should wrap to the same bookmark
                }
            }
            context("persistence") {
                // Checks that bookmarks persist across sessions.
                it("persists bookmarks across sessions") {
                    // Clean UserDefaults before test
                    let key = "\(AppSettings.appName)Bookmarks"
                    UserDefaults.standard.removeObject(forKey: key)

                    // Add bookmarks
                    bookmarkManager.addBookmark(fileName: testFileName, line: 10, description: "Persistent bookmark 1")
                    bookmarkManager.addBookmark(fileName: testFileName, line: 20, description: "Persistent bookmark 2")

                    expect(bookmarkManager.bookmarks.count).to(equal(2))

                    // Create a new bookmark manager (simulating app restart)
                    let newBookmarkManager = BookmarkManager()

                    // Verify bookmarks were loaded from persistence
                    let count = newBookmarkManager.bookmarks.count
                    expect(count).to(equal(2), description: "Expected 2 bookmarks after reload, got \(count)")
                    guard count == 2 else {
                        // Clean up after test
                        UserDefaults.standard.removeObject(forKey: key)
                        return
                    }

                    let loadedBookmarks = newBookmarkManager.bookmarks.sorted { $0.line < $1.line }
                    expect(loadedBookmarks[0].fileName).to(equal(testFileName))
                    expect(loadedBookmarks[0].line).to(equal(10))
                    expect(loadedBookmarks[0].description).to(equal("Persistent bookmark 1"))
                    expect(loadedBookmarks[1].line).to(equal(20))
                    expect(loadedBookmarks[1].description).to(equal("Persistent bookmark 2"))

                    // Clean up after test
                    UserDefaults.standard.removeObject(forKey: key)
                }
                // Checks that bookmark removal persists across sessions.
                it("persists bookmark removal across sessions") {
                    // Add bookmarks
                    bookmarkManager.addBookmark(fileName: testFileName, line: 10, description: removedDescription)
                    bookmarkManager.addBookmark(fileName: testFileName, line: 20, description: keptDescription)

                    // Remove one bookmark
                    let bookmarkToRemove = bookmarkManager.bookmarks.first { $0.line == 10 && $0.description == removedDescription }!
                    bookmarkManager.removeBookmark(bookmarkToRemove)

                    // Create a new bookmark manager (simulating app restart)
                    let newBookmarkManager = BookmarkManager()

                    // Verify only the remaining bookmark was loaded
                    expect(newBookmarkManager.bookmarks.count).to(equal(1))
                    expect(newBookmarkManager.bookmarks.first?.line).to(equal(20))
                    expect(newBookmarkManager.bookmarks.first?.description).to(equal(keptDescription))
                }
            }
            context("bookmark model") {
                // Checks that a bookmark initializes with correct fields.
                it("initializes correctly") {
                    let bookmark = BookmarkManager.Bookmark(fileName: testFileName, line: 42, description: "Test bookmark")

                    expect(bookmark.id).toNot(beNil())
                    expect(bookmark.fileName).to(equal(testFileName))
                    expect(bookmark.line).to(equal(42))
                    expect(bookmark.description).to(equal("Test bookmark"))
                    expect(bookmark.timestamp).toNot(beNil())

                    // Verify timestamp is recent (within last second)
                    let now = Date()
                    expect(abs(bookmark.timestamp.timeIntervalSince(now))).to(beLessThan(1.0))
                }
                // Checks that each bookmark is uniquely identifiable.
                it("ensures each bookmark is identifiable") {
                    let bookmark1 = BookmarkManager.Bookmark(fileName: testFileName, line: 10, description: "Bookmark 1")
                    let bookmark2 = BookmarkManager.Bookmark(fileName: testFileName, line: 10, description: "Bookmark 2")

                    expect(bookmark1.id).toNot(equal(bookmark2.id)) // Each bookmark should have unique ID
                }
            }
            context("edge cases") {
                // Checks that bookmarks with empty descriptions are allowed.
                it("allows bookmarks with empty descriptions") {
                    bookmarkManager.addBookmark(fileName: testFileName, line: 10, description: "")

                    expect(bookmarkManager.bookmarks.count).to(equal(1))
                    expect(bookmarkManager.bookmarks.first?.description).to(equal(""))
                }
                // Checks that bookmarks with zero line number are allowed.
                it("allows bookmarks with zero line number") {
                    bookmarkManager.addBookmark(fileName: testFileName, line: 0, description: "First line bookmark")

                    expect(bookmarkManager.bookmarks.count).to(equal(1))
                    expect(bookmarkManager.bookmarks.first?.line).to(equal(0))
                }
                // Checks that bookmarks with negative line numbers are allowed.
                it("allows bookmarks with negative line numbers") {
                    bookmarkManager.addBookmark(fileName: testFileName, line: -5, description: "Negative line bookmark")

                    expect(bookmarkManager.bookmarks.count).to(equal(1))
                    expect(bookmarkManager.bookmarks.first?.line).to(equal(-5)) // Should allow negative lines
                }
            }
        }
    }
}
