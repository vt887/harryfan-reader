//
//  TextDocumentTests.swift
//  HarryFanReaderTests
//
//  Created by @vt887 on 9/29/25.
//

@testable import HarryFan_Reader
import XCTest

final class TextDocumentTests: XCTestCase {
    var textDocument: TextDocument!

    override func setUp() {
        super.setUp()
        textDocument = TextDocument()
    }

    override func tearDown() {
        textDocument = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialState() {
        XCTAssertEqual(textDocument.content.count, 0)
        XCTAssertEqual(textDocument.currentLine, 0)
        XCTAssertEqual(textDocument.totalLines, 0)
        XCTAssertEqual(textDocument.encoding, "Unknown")
        XCTAssertEqual(textDocument.fileName, "")
        XCTAssertTrue(textDocument.removeEmptyLines)
    }

    // MARK: - Welcome Text Tests

    func testLoadWelcomeText() {
        textDocument.loadWelcomeText()

        XCTAssertGreaterThan(textDocument.content.count, 0)
        XCTAssertEqual(textDocument.totalLines, textDocument.content.count)
        XCTAssertEqual(textDocument.currentLine, 0)
        XCTAssertEqual(textDocument.fileName, "")
        XCTAssertEqual(textDocument.encoding, "ASCII")
        // Welcome message should contain the app name somewhere
        let contentText = textDocument.content.joined(separator: " ")
        XCTAssertTrue(contentText.contains("HarryFan Reader"))
    }

    // MARK: - Navigation Tests

    func testGotoLine() {
        // Setup test content
        textDocument.content = ["Line 1", "Line 2", "Line 3", "Line 4", "Line 5"]
        textDocument.totalLines = 5

        // Test valid line navigation
        textDocument.gotoLine(3)
        XCTAssertEqual(textDocument.currentLine, 2) // 0-indexed

        // Test boundary conditions
        textDocument.gotoLine(1)
        XCTAssertEqual(textDocument.currentLine, 0)

        textDocument.gotoLine(10) // Beyond total lines
        XCTAssertEqual(textDocument.currentLine, 4) // Should clamp to last line

        textDocument.gotoLine(-5) // Negative line
        XCTAssertEqual(textDocument.currentLine, 0) // Should clamp to first line
    }

    func testGotoStart() {
        textDocument.content = ["Line 1", "Line 2", "Line 3"]
        textDocument.totalLines = 3
        textDocument.currentLine = 2

        textDocument.gotoStart()
        XCTAssertEqual(textDocument.currentLine, 0)
    }

    func testGotoEnd() {
        textDocument.content = ["Line 1", "Line 2", "Line 3"]
        textDocument.totalLines = 3
        textDocument.currentLine = 0

        textDocument.gotoEnd()
        XCTAssertEqual(textDocument.currentLine, 2)
    }

    func testGotoEndWithEmptyDocument() {
        textDocument.content = []
        textDocument.totalLines = 0

        textDocument.gotoEnd()
        XCTAssertEqual(textDocument.currentLine, 0) // Should stay at 0 for empty document
    }

    func testPageUp() {
        textDocument.content = Array(1 ... 50).map { "Line \($0)" }
        textDocument.totalLines = 50
        textDocument.currentLine = 30

        textDocument.pageUp()
        XCTAssertEqual(textDocument.currentLine, 10) // 30 - 20 (page size)
    }

    func testPageUpAtBeginning() {
        textDocument.content = Array(1 ... 50).map { "Line \($0)" }
        textDocument.totalLines = 50
        textDocument.currentLine = 5

        textDocument.pageUp()
        XCTAssertEqual(textDocument.currentLine, 0) // Should clamp to 0
    }

    func testPageDown() {
        textDocument.content = Array(1 ... 50).map { "Line \($0)" }
        textDocument.totalLines = 50
        textDocument.currentLine = 10

        textDocument.pageDown()
        XCTAssertEqual(textDocument.currentLine, 30) // 10 + 20 (page size)
    }

    func testPageDownAtEnd() {
        textDocument.content = Array(1 ... 50).map { "Line \($0)" }
        textDocument.totalLines = 50
        textDocument.currentLine = 45

        textDocument.pageDown()
        XCTAssertEqual(textDocument.currentLine, 49) // Should clamp to last line (0-indexed)
    }

    // MARK: - Search Tests

    func testSearchForward() {
        textDocument.content = ["Hello world", "This is a test", "Hello again", "Final line"]
        textDocument.totalLines = 4
        textDocument.currentLine = 0

        let result = textDocument.search("Hello", direction: .forward)
        XCTAssertEqual(result, 2) // Should find "Hello again" at index 2
    }

    func testSearchForwardCaseSensitive() {
        textDocument.content = ["hello world", "This is a test", "Hello again", "Final line"]
        textDocument.totalLines = 4
        textDocument.currentLine = 0

        let result = textDocument.search("Hello", direction: .forward, caseSensitive: true)
        XCTAssertEqual(result, 2) // Should find "Hello again" at index 2
    }

    func testSearchForwardCaseInsensitive() {
        textDocument.content = ["hello world", "This is a test", "Hello again", "Final line"]
        textDocument.totalLines = 4
        textDocument.currentLine = 0

        // Case insensitive search should find "hello world" when wrapping around
        textDocument.currentLine = 2 // Start from line 2
        let result = textDocument.search("Hello", direction: .forward, caseSensitive: false)
        XCTAssertEqual(result, 0) // Should wrap around and find "hello world" at index 0
    }

    func testSearchBackward() {
        textDocument.content = ["Hello world", "This is a test", "Hello again", "Final line"]
        textDocument.totalLines = 4
        textDocument.currentLine = 3

        let result = textDocument.search("Hello", direction: .backward)
        XCTAssertEqual(result, 2) // Should find "Hello again" at index 2
    }

    func testSearchNotFound() {
        textDocument.content = ["Hello world", "This is a test", "Hello again", "Final line"]
        textDocument.totalLines = 4
        textDocument.currentLine = 0

        let result = textDocument.search("NotFound", direction: .forward)
        XCTAssertNil(result)
    }

    func testSearchEmptyQuery() {
        textDocument.content = ["Hello world", "This is a test"]
        textDocument.totalLines = 2
        textDocument.currentLine = 0

        let result = textDocument.search("", direction: .forward)
        XCTAssertNil(result)
    }

    func testSearchWrapAround() {
        textDocument.content = ["Hello world", "This is a test", "Another line", "Final line"]
        textDocument.totalLines = 4
        textDocument.currentLine = 2

        let result = textDocument.search("Hello", direction: .forward)
        XCTAssertEqual(result, 0) // Should wrap around and find "Hello world" at index 0
    }

    // MARK: - Content Access Tests

    func testGetCurrentLine() {
        textDocument.content = ["First line", "Second line", "Third line"]
        textDocument.totalLines = 3
        textDocument.currentLine = 1

        let currentLine = textDocument.getCurrentLine()
        XCTAssertEqual(currentLine, "Second line")
    }

    func testGetCurrentLineOutOfBounds() {
        textDocument.content = ["First line", "Second line"]
        textDocument.totalLines = 2
        textDocument.currentLine = 5

        let currentLine = textDocument.getCurrentLine()
        XCTAssertEqual(currentLine, "")
    }

    func testGetCurrentLineEmptyDocument() {
        textDocument.content = []
        textDocument.totalLines = 0
        textDocument.currentLine = 0

        let currentLine = textDocument.getCurrentLine()
        XCTAssertEqual(currentLine, "")
    }

    func testGetVisibleLines() {
        textDocument.content = Array(1 ... 50).map { "Line \($0)" }
        textDocument.totalLines = 50
        textDocument.currentLine = 10

        let visibleLines = textDocument.getVisibleLines()
        XCTAssertEqual(visibleLines.count, 24) // Default visible lines
        XCTAssertEqual(visibleLines.first, "Line 11") // currentLine + 1 (1-indexed display)
        XCTAssertEqual(visibleLines.last, "Line 34")
    }

    func testGetVisibleLinesNearEnd() {
        textDocument.content = Array(1 ... 10).map { "Line \($0)" }
        textDocument.totalLines = 10
        textDocument.currentLine = 5

        let visibleLines = textDocument.getVisibleLines()
        XCTAssertEqual(visibleLines.count, 5) // Only 5 lines remaining
        XCTAssertEqual(visibleLines.first, "Line 6")
        XCTAssertEqual(visibleLines.last, "Line 10")
    }

    // MARK: - Title Bar Tests

    func testGetTitleBarTextEmptyFile() {
        let titleBarText = textDocument.getTitleBarText()
        XCTAssertTrue(titleBarText.contains("HarryFan Reader"))
        XCTAssertEqual(titleBarText.count, 80) // Should be padded to 80 characters
    }

    func testGetTitleBarTextWithFile() {
        textDocument.fileName = "test.txt"
        textDocument.content = Array(1 ... 100).map { "Line \($0)" }
        textDocument.totalLines = 100
        textDocument.currentLine = 49 // 50th line (1-indexed)
        textDocument.encoding = "CP866"

        let titleBarText = textDocument.getTitleBarText()
        XCTAssertTrue(titleBarText.contains("HarryFan Reader"))
        XCTAssertTrue(titleBarText.contains("test.txt"))
        XCTAssertTrue(titleBarText.contains("Line 50 of 100"))
        XCTAssertTrue(titleBarText.contains("50%"))
        XCTAssertTrue(titleBarText.contains("CP866"))
        XCTAssertEqual(titleBarText.count, 80)
    }

    func testGetTitleBarTextLongFileName() {
        textDocument.fileName = "this_is_a_very_long_filename_that_should_be_truncated_in_the_title_bar.txt"
        textDocument.content = ["Line 1"]
        textDocument.totalLines = 1
        textDocument.currentLine = 0
        textDocument.encoding = "ASCII"

        let titleBarText = textDocument.getTitleBarText()
        XCTAssertTrue(titleBarText.contains("...")) // Should be truncated
        XCTAssertEqual(titleBarText.count, 80)
    }

    // MARK: - Menu Bar Tests

    func testGetMenuBarText() {
        let menuBarText = textDocument.getMenuBarText()
        XCTAssertFalse(menuBarText.isEmpty)
        XCTAssertEqual(menuBarText.count, 80)

        // Should contain some expected menu items
        XCTAssertTrue(menuBarText.contains("Help"))
        XCTAssertTrue(menuBarText.contains("Quit"))

        // Should contain numbered items
        XCTAssertTrue(menuBarText.contains("1"))
        XCTAssertTrue(menuBarText.contains("10"))
    }

    // MARK: - File Operations Tests

    func testCloseFile() {
        // Setup document with content
        textDocument.fileName = "test.txt"
        textDocument.content = ["Line 1", "Line 2"]
        textDocument.totalLines = 2
        textDocument.currentLine = 1
        textDocument.encoding = "CP866"

        textDocument.closeFile()

        XCTAssertEqual(textDocument.content.count, 0)
        XCTAssertEqual(textDocument.currentLine, 0)
        XCTAssertEqual(textDocument.totalLines, 0)
        XCTAssertEqual(textDocument.encoding, "Unknown")
        XCTAssertEqual(textDocument.fileName, "")
    }

    // MARK: - Messages Tests

    func testQuitMessage() {
        let quitMessage = textDocument.quitMessage
        XCTAssertFalse(quitMessage.isEmpty)
        XCTAssertTrue(quitMessage.contains("Thank you"))
    }
}
