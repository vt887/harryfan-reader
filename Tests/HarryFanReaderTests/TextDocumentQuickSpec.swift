//
//  TextDocumentTests.swift
//  HarryFanReaderTests
//
//  Created by @vt887 on 9/29/25.
//

@testable import HarryFanReader
import Nimble
import Quick

final class TextDocumentQuickSpec: QuickSpec {
    override class func spec() {
        var textDocument: TextDocument!

        beforeEach {
            textDocument = TextDocument()
        }
        afterEach {
            textDocument = nil
        }

        describe("TextDocument") {
            context("initial state") {
                // Checks that a new TextDocument has correct default values.
                it("has correct default values") {
                    expect(textDocument.content.count).to(equal(0))
                    expect(textDocument.currentLine).to(equal(0))
                    expect(textDocument.totalLines).to(equal(0))
                    expect(textDocument.encoding).to(equal("Unknown"))
                    expect(textDocument.fileName).to(equal(""))
                    expect(textDocument.removeEmptyLines).to(beTrue())
                }
            }
            context("welcome text") {
                // Checks that loading the welcome text populates content and sets expected fields.
                it("loads welcome text") {
                    textDocument.loadWelcomeText()
                    expect(textDocument.content.count).to(beGreaterThan(0))
                    expect(textDocument.totalLines).to(equal(textDocument.content.count))
                    expect(textDocument.currentLine).to(equal(0))
                    expect(textDocument.fileName).to(equal(""))
                    expect(textDocument.encoding).to(equal("Unknown"))
                    let contentText = textDocument.content.joined(separator: " ")
                    expect(contentText).to(contain("HarryFan Reader"))
                    expect(textDocument.totalLines).to(equal(AppSettings.rows - 2))
                }
            }
            context("navigation") {
                // Checks that gotoLine navigates to the correct line and handles boundaries.
                it("navigates to a specific line") {
                    // Setup test content
                    textDocument.content = ["Line 1", "Line 2", "Line 3", "Line 4", "Line 5"]
                    textDocument.totalLines = 5

                    // Test valid line navigation
                    textDocument.gotoLine(3)
                    expect(textDocument.currentLine).to(equal(2))

                    // Test boundary conditions
                    textDocument.gotoLine(1)
                    expect(textDocument.currentLine).to(equal(0))

                    textDocument.gotoLine(10) // Beyond total lines
                    expect(textDocument.currentLine).to(equal(4)) // Should clamp to last line

                    textDocument.gotoLine(-5) // Negative line
                    expect(textDocument.currentLine).to(equal(0)) // Should clamp to first line
                }

                // Checks that gotoStart moves to the first line.
                it("navigates to the start") {
                    textDocument.content = ["Line 1", "Line 2", "Line 3"]
                    textDocument.totalLines = 3
                    textDocument.currentLine = 2

                    textDocument.gotoStart()
                    expect(textDocument.currentLine).to(equal(0))
                }

                // Checks that gotoEnd moves to the last line.
                it("navigates to the end") {
                    textDocument.content = ["Line 1", "Line 2", "Line 3"]
                    textDocument.totalLines = 3
                    textDocument.currentLine = 0

                    textDocument.gotoEnd()
                    expect(textDocument.currentLine).to(equal(2))
                }

                // Checks that gotoEnd on an empty document does not crash.
                it("handles empty document when navigating to the end") {
                    textDocument.content = []
                    textDocument.totalLines = 0

                    textDocument.gotoEnd()
                    expect(textDocument.currentLine).to(equal(0))
                }

                // Checks that pageUp moves up by a page.
                it("pages up") {
                    textDocument.content = Array(1 ... 50).map { "Line \($0)" }
                    textDocument.totalLines = 50
                    textDocument.currentLine = 30

                    textDocument.pageUp()
                    expect(textDocument.currentLine).to(equal(10))
                }

                // Checks that pageUp at the beginning clamps to the first line.
                it("handles page up at the beginning") {
                    textDocument.content = Array(1 ... 50).map { "Line \($0)" }
                    textDocument.totalLines = 50
                    textDocument.currentLine = 5

                    textDocument.pageUp()
                    expect(textDocument.currentLine).to(equal(0))
                }

                // Checks that pageDown moves down by a page.
                it("pages down") {
                    textDocument.content = Array(1 ... 50).map { "Line \($0)" }
                    textDocument.totalLines = 50
                    textDocument.currentLine = 10

                    textDocument.pageDown()
                    expect(textDocument.currentLine).to(equal(30))
                }

                // Checks that pageDown at the end clamps to the last line.
                it("handles page down at the end") {
                    textDocument.content = Array(1 ... 50).map { "Line \($0)" }
                    textDocument.totalLines = 50
                    textDocument.currentLine = 45

                    textDocument.pageDown()
                    expect(textDocument.currentLine).to(equal(49))
                }
            }
            context("search") {
                // Checks that search finds the next matching line forward.
                it("searches forward") {
                    textDocument.content = ["Hello world", "This is a test", "Hello again", "Final line"]
                    textDocument.totalLines = 4
                    textDocument.currentLine = 0
                    let result = textDocument.search("Hello", direction: .forward)
                    expect(result).to(equal(2))
                }

                // Checks that search forward is case sensitive.
                it("searches forward case sensitively") {
                    textDocument.content = ["hello world", "This is a test", "Hello again", "Final line"]
                    textDocument.totalLines = 4
                    textDocument.currentLine = 0
                    let result = textDocument.search("Hello", direction: .forward, caseSensitive: true)
                    expect(result).to(equal(2))
                }

                // Checks that search forward is case insensitive.
                it("searches forward case insensitively") {
                    textDocument.content = ["hello world", "This is a test", "Hello again", "Final line"]
                    textDocument.totalLines = 4
                    textDocument.currentLine = 0
                    textDocument.currentLine = 2
                    let result = textDocument.search("Hello", direction: .forward, caseSensitive: false)
                    expect(result).to(equal(0))
                }

                // Checks that search finds the previous matching line backward.
                it("searches backward") {
                    textDocument.content = ["Hello world", "This is a test", "Hello again", "Final line"]
                    textDocument.totalLines = 4
                    textDocument.currentLine = 3
                    let result = textDocument.search("Hello", direction: .backward)
                    expect(result).to(equal(2))
                }

                // Checks that search returns nil if the term is not found.
                it("returns nil when search term is not found") {
                    textDocument.content = ["Hello world", "This is a test", "Hello again", "Final line"]
                    textDocument.totalLines = 4
                    textDocument.currentLine = 0
                    let result = textDocument.search("NotFound", direction: .forward)
                    expect(result).to(beNil())
                }

                // Checks that search returns nil for an empty query.
                it("returns nil for empty search query") {
                    textDocument.content = ["Hello world", "This is a test"]
                    textDocument.totalLines = 2
                    textDocument.currentLine = 0
                    let result = textDocument.search("", direction: .forward)
                    expect(result).to(beNil())
                }

                // Checks that search wraps around when searching.
                it("wraps around when searching") {
                    textDocument.content = ["Hello world", "This is a test", "Another line", "Final line"]
                    textDocument.totalLines = 4
                    textDocument.currentLine = 2
                    let result = textDocument.search("Hello", direction: .forward)
                    expect(result).to(equal(0))
                }
            }
            context("content access") {
                // Checks that getCurrentLine returns the correct line.
                it("gets the current line") {
                    textDocument.content = ["First line", "Second line"]
                    textDocument.totalLines = 2
                    textDocument.currentLine = 1
                    let currentLine = textDocument.getCurrentLine()
                    expect(currentLine).to(equal("Second line"))
                }

                // Checks that getCurrentLine returns empty string if out of bounds.
                it("returns empty string for current line out of bounds") {
                    textDocument.content = ["First line", "Second line"]
                    textDocument.totalLines = 2
                    textDocument.currentLine = 5
                    let currentLine = textDocument.getCurrentLine()
                    expect(currentLine).to(equal(""))
                }

                // Checks that getCurrentLine returns empty string for empty document.
                it("returns empty string for current line in empty document") {
                    textDocument.content = []
                    textDocument.totalLines = 0
                    textDocument.currentLine = 0
                    let currentLine = textDocument.getCurrentLine()
                    expect(currentLine).to(equal(""))
                }

                // Checks that getVisibleLines returns the correct visible lines.
                it("gets visible lines") {
                    textDocument.content = Array(1 ... 50).map { "Line \($0)" }
                    textDocument.totalLines = 50
                    textDocument.currentLine = 10
                    let visibleLines = textDocument.getVisibleLines()
                    expect(visibleLines.count).to(equal(22)) // AppSettings.rows - 2 (title + menu bars)
                    expect(visibleLines.first).to(equal("Line 1")) // topLine starts at 0
                    expect(visibleLines.last).to(equal("Line 22")) // first 22 lines visible
                }

                // Checks that getVisibleLines near the end returns all lines.
                it("gets visible lines near the end") {
                    textDocument.content = Array(1 ... 10).map { "Line \($0)" }
                    textDocument.totalLines = 10
                    textDocument.currentLine = 5
                    let visibleLines = textDocument.getVisibleLines()
                    expect(visibleLines.count).to(equal(10)) // All lines fit within 22 row limit
                    expect(visibleLines.first).to(equal("Line 1")) // Shows all content from start
                    expect(visibleLines.last).to(equal("Line 10")) // Shows all content to end
                }
            }
            context("title bar") {
                // Checks that getTitleBarText returns correct text for empty file.
                it("gets title bar text for empty file") {
                    let titleBarText = textDocument.getTitleBarText()
                    expect(titleBarText).to(contain("HarryFan Reader"))
                    expect(titleBarText).to(contain(" │ "))
                    expect(titleBarText.count).to(equal(AppSettings.cols))
                }

                // Checks that getTitleBarText returns correct text with file name.
                it("gets title bar text with file name") {
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

                // Checks that getTitleBarText truncates long file names.
                it("truncates long file name in title bar") {
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
            }
            context("menu bar") {
                // Checks that getMenuBarText returns correct menu bar text.
                it("gets menu bar text") {
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
            }
            context("file operations") {
                // Checks that closeFile resets the document state.
                it("closes the file") {
                    textDocument.fileName = "test.txt"
                    textDocument.content = ["Line 1", "Line 2"]
                    textDocument.totalLines = 2
                    textDocument.currentLine = 1
                    textDocument.encoding = "CP866"
                    textDocument.closeFile()
                    expect(textDocument.content.count).to(equal(0))
                    expect(textDocument.currentLine).to(equal(0))
                    expect(textDocument.totalLines).to(equal(0))
                    expect(textDocument.encoding).to(equal("Unknown"))
                    expect(textDocument.fileName).to(equal(""))
                }
            }
            context("messages") {
                // Checks that the quit message is present and contains expected content.
                it("shows quit message") {
                    let quitMessage = textDocument.quitMessage
                    expect(quitMessage.isEmpty).to(beFalse())
                    expect(quitMessage).to(contain("Thank you"))
                }
            }
        }

        describe("TextDocument navigation (QuickSpec)") {
            var doc: TextDocument!

            beforeEach {
                doc = TextDocument()
            }

            context("when paging down") {
                beforeEach {
                    doc.content = Array(1 ... 50).map { "Line \($0)" }
                    doc.totalLines = 50
                    doc.currentLine = 10
                }

                it("advances by one page with overlap") {
                    doc.pageDown()
                    expect(doc.currentLine).to(equal(30)) // rows=24 -> page step 20
                }
            }

            context("when going to the end") {
                beforeEach {
                    doc.content = ["Line 1", "Line 2", "Line 3"]
                    doc.totalLines = 3
                    doc.currentLine = 0
                }

                it("moves the cursor to the last line") {
                    doc.gotoEnd()
                    expect(doc.currentLine).to(equal(2))
                }
            }
        }

        describe("Title bar formatting (QuickSpec)") {
            it("fits exactly the configured width and shows percent") {
                let doc = TextDocument()
                doc.fileName = "test.txt"
                doc.content = Array(1 ... 100).map { "Line \($0)" }
                doc.totalLines = 100
                doc.currentLine = 49 // 50%

                let title = doc.getTitleBarText()
                expect(title.count).to(equal(AppSettings.cols))
                expect(title).to(contain("HarryFan Reader"))
                expect(title).to(contain("test.txt"))
                expect(title).to(satisfyAnyOf(contain("50%")))
                expect(title).to(contain(" │ "))
            }
        }
    }
}
