//
//  TextDocumentTests.swift
//  HarryFanReaderTests
//
//  Created by @vt887 on 9/29/25.
//

@testable import HarryFanReader
import XCTest
import Nimble

// Unit tests for TextDocument
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
        expect(self.textDocument.content.count).to(equal(0))
        expect(self.textDocument.currentLine).to(equal(0))
        expect(self.textDocument.totalLines).to(equal(0))
        expect(self.textDocument.encoding).to(equal("Unknown"))
        expect(self.textDocument.fileName).to(equal(""))
        expect(self.textDocument.removeEmptyLines).to(beTrue())
    }

    // MARK: - Welcome Text Tests

    func testLoadWelcomeText() {
        textDocument.loadWelcomeText()
        expect(self.textDocument.content.count).to(beGreaterThan(0))
        expect(self.textDocument.totalLines).to(equal(self.textDocument.content.count))
        expect(self.textDocument.currentLine).to(equal(0))
        expect(self.textDocument.fileName).to(equal(""))
        expect(self.textDocument.encoding).to(equal("Unknown"))
        let contentText = textDocument.content.joined(separator: " ")
        expect(contentText).to(contain("HarryFan Reader"))
        expect(self.textDocument.totalLines).to(equal(AppSettings.rows - 2))
    }

    // MARK: - Navigation Tests

    func testGotoLine() {
        // Setup test content
        textDocument.content = ["Line 1", "Line 2", "Line 3", "Line 4", "Line 5"]
        textDocument.totalLines = 5

        // Test valid line navigation
        textDocument.gotoLine(3)
        expect(self.textDocument.currentLine).to(equal(2))

        // Test boundary conditions
        textDocument.gotoLine(1)
        expect(self.textDocument.currentLine).to(equal(0))

        textDocument.gotoLine(10) // Beyond total lines
        expect(self.textDocument.currentLine).to(equal(4)) // Should clamp to last line

        textDocument.gotoLine(-5) // Negative line
        expect(self.textDocument.currentLine).to(equal(0)) // Should clamp to first line
    }

    func testGotoStart() {
        textDocument.content = ["Line 1", "Line 2", "Line 3"]
        textDocument.totalLines = 3
        textDocument.currentLine = 2

        textDocument.gotoStart()
        expect(self.textDocument.currentLine).to(equal(0))
    }

    func testGotoEnd() {
        textDocument.content = ["Line 1", "Line 2", "Line 3"]
        textDocument.totalLines = 3
        textDocument.currentLine = 0

        textDocument.gotoEnd()
        expect(self.textDocument.currentLine).to(equal(2))
    }

    func testGotoEndWithEmptyDocument() {
        textDocument.content = []
        textDocument.totalLines = 0

        textDocument.gotoEnd()
        expect(self.textDocument.currentLine).to(equal(0))
    }

    func testPageUp() {
        textDocument.content = Array(1 ... 50).map { "Line \($0)" }
        textDocument.totalLines = 50
        textDocument.currentLine = 30

        textDocument.pageUp()
        expect(self.textDocument.currentLine).to(equal(10))
    }

    func testPageUpAtBeginning() {
        textDocument.content = Array(1 ... 50).map { "Line \($0)" }
        textDocument.totalLines = 50
        textDocument.currentLine = 5

        textDocument.pageUp()
        expect(self.textDocument.currentLine).to(equal(0))
    }

    func testPageDown() {
        textDocument.content = Array(1 ... 50).map { "Line \($0)" }
        textDocument.totalLines = 50
        textDocument.currentLine = 10

        textDocument.pageDown()
        expect(self.textDocument.currentLine).to(equal(30))
    }

    func testPageDownAtEnd() {
        textDocument.content = Array(1 ... 50).map { "Line \($0)" }
        textDocument.totalLines = 50
        textDocument.currentLine = 45

        textDocument.pageDown()
        expect(self.textDocument.currentLine).to(equal(49))
    }

    // MARK: - Search Tests

    func testSearchForward() {
        textDocument.content = ["Hello world", "This is a test", "Hello again", "Final line"]
        textDocument.totalLines = 4
        textDocument.currentLine = 0
        let result = textDocument.search("Hello", direction: .forward)
        expect(result).to(equal(2))
    }

    func testSearchForwardCaseSensitive() {
        textDocument.content = ["hello world", "This is a test", "Hello again", "Final line"]
        textDocument.totalLines = 4
        textDocument.currentLine = 0
        let result = textDocument.search("Hello", direction: .forward, caseSensitive: true)
        expect(result).to(equal(2))
    }

    func testSearchForwardCaseInsensitive() {
        textDocument.content = ["hello world", "This is a test", "Hello again", "Final line"]
        textDocument.totalLines = 4
        textDocument.currentLine = 0
        textDocument.currentLine = 2
        let result = textDocument.search("Hello", direction: .forward, caseSensitive: false)
        expect(result).to(equal(0))
    }

    func testSearchBackward() {
        textDocument.content = ["Hello world", "This is a test", "Hello again", "Final line"]
        textDocument.totalLines = 4
        textDocument.currentLine = 3
        let result = textDocument.search("Hello", direction: .backward)
        expect(result).to(equal(2))
    }

    func testSearchNotFound() {
        textDocument.content = ["Hello world", "This is a test", "Hello again", "Final line"]
        textDocument.totalLines = 4
        textDocument.currentLine = 0
        let result = textDocument.search("NotFound", direction: .forward)
        expect(result).to(beNil())
    }

    func testSearchEmptyQuery() {
        textDocument.content = ["Hello world", "This is a test"]
        textDocument.totalLines = 2
        textDocument.currentLine = 0
        let result = textDocument.search("", direction: .forward)
        expect(result).to(beNil())
    }

    func testSearchWrapAround() {
        textDocument.content = ["Hello world", "This is a test", "Another line", "Final line"]
        textDocument.totalLines = 4
        textDocument.currentLine = 2
        let result = textDocument.search("Hello", direction: .forward)
        expect(result).to(equal(0))
    }

    // MARK: - Content Access Tests

    func testGetCurrentLine() {
        textDocument.content = ["First line", "Second line"]
        textDocument.totalLines = 2
        textDocument.currentLine = 1
        let currentLine = textDocument.getCurrentLine()
        expect(currentLine).to(equal("Second line"))
    }

    func testGetCurrentLineOutOfBounds() {
        textDocument.content = ["First line", "Second line"]
        textDocument.totalLines = 2
        textDocument.currentLine = 5
        let currentLine = textDocument.getCurrentLine()
        expect(currentLine).to(equal(""))
    }

    func testGetCurrentLineEmptyDocument() {
        textDocument.content = []
        textDocument.totalLines = 0
        textDocument.currentLine = 0
        let currentLine = textDocument.getCurrentLine()
        expect(currentLine).to(equal(""))
    }

    func testGetVisibleLines() {
        textDocument.content = Array(1 ... 50).map { "Line \($0)" }
        textDocument.totalLines = 50
        textDocument.currentLine = 10
        let visibleLines = textDocument.getVisibleLines()
        XCTAssertEqual(visibleLines.count, 22) // AppSettings.rows - 2 (title + menu bars)
        XCTAssertEqual(visibleLines.first, "Line 1") // topLine starts at 0
        XCTAssertEqual(visibleLines.last, "Line 22") // first 22 lines visible
    }

    func testGetVisibleLinesNearEnd() {
        textDocument.content = Array(1 ... 10).map { "Line \($0)" }
        textDocument.totalLines = 10
        textDocument.currentLine = 5
        let visibleLines = textDocument.getVisibleLines()
        XCTAssertEqual(visibleLines.count, 10) // All lines fit within 22 row limit
        XCTAssertEqual(visibleLines.first, "Line 1") // Shows all content from start
        XCTAssertEqual(visibleLines.last, "Line 10") // Shows all content to end
    }

    // MARK: - Title Bar Tests

    func testGetTitleBarTextEmptyFile() {
        let titleBarText = textDocument.getTitleBarText()
        expect(titleBarText).to(contain("HarryFan Reader"))
        expect(titleBarText).to(contain(" │ "))
        expect(titleBarText.count).to(equal(AppSettings.cols))
    }

    func testGetTitleBarTextWithFile() {
        textDocument.fileName = "test.txt"
        textDocument.content = Array(1 ... 100).map { "Line \($0)" }
        textDocument.totalLines = 100
        textDocument.currentLine = 49
        textDocument.encoding = "CP866"
        let titleBarText = textDocument.getTitleBarText()
        expect(titleBarText).to(contain("HarryFan Reader"))
        expect(titleBarText).to(contain("test.txt"))
        expect(titleBarText).to(satisfyAnyOf(contain("Line 50 of 100"), contain("50%")))
        expect(titleBarText).to(contain(" │ "))
        expect(titleBarText.count).to(equal(AppSettings.cols))
    }

    func testGetTitleBarTextLongFileName() {
        textDocument.fileName = "this_is_a_very_long_filename_that_should_be_truncated_in_the_title_bar.txt"
        textDocument.content = ["Line 1"]
        textDocument.totalLines = 1
        textDocument.currentLine = 0
        textDocument.encoding = "ASCII"
        let titleBarText = textDocument.getTitleBarText()
        expect(titleBarText).to(contain("..."))
        expect(titleBarText).to(contain(" │ "))
        expect(titleBarText.count).to(equal(AppSettings.cols))
    }

    // MARK: - Menu Bar Tests

    func testGetMenuBarText() {
        let testItems = ["Help", "Wrap", "Open", "Search", "Goto", "Bookm", "Start", "End", "Menu", "Qu"]
        let menuBarText = textDocument.getMenuBarText(testItems)
        expect(menuBarText.isEmpty).to(beFalse())
        expect(menuBarText.count).to(equal(AppSettings.cols))
        expect(menuBarText).to(contain("Help"))
        expect(menuBarText).to(contain("Qu"))
        expect(menuBarText).to(contain(" 1Help"))
        expect(menuBarText).to(contain(" 10Qu"))
        expect(menuBarText).to(contain(" 1Help  "))
    }

    // MARK: - File Operations Tests

    func testCloseFile() {
        self.textDocument.fileName = "test.txt"
        self.textDocument.content = ["Line 1", "Line 2"]
        self.textDocument.totalLines = 2
        self.textDocument.currentLine = 1
        self.textDocument.encoding = "CP866"
        self.textDocument.closeFile()
        expect(self.textDocument.content.count).to(equal(0))
        expect(self.textDocument.currentLine).to(equal(0))
        expect(self.textDocument.totalLines).to(equal(0))
        expect(self.textDocument.encoding).to(equal("Unknown"))
        expect(self.textDocument.fileName).to(equal(""))
    }

    // MARK: - Messages Tests

    func testQuitMessage() {
        let quitMessage = textDocument.quitMessage
        expect(quitMessage.isEmpty).to(beFalse())
        expect(quitMessage).to(contain("Thank you"))
    }
}
