//
//  OverlayFactoryStatisticsQuickSpec.swift
//  HarryFanReaderTests
//
//  Created by @vt887 on 10/15/25.
//

@testable import HarryFanReader
import Nimble
import Quick

// Helper: convert a ScreenLayer row (array of ScreenCell) into a String
private func rowToString(_ row: [ScreenCell]) -> String {
    var chars: [Character] = []
    chars.reserveCapacity(row.count)
    for cell in row {
        chars.append(cell.char)
    }
    return String(chars)
}

// Helper: count words in a line using the same split logic but keep it out of nested closures
private func countWords(in line: String) -> Int {
    line.split { $0.isWhitespace }.count
}

final class OverlayFactoryStatisticsQuickSpec: QuickSpec {
    override class func spec() {
        describe("OverlayFactory statistics overlay") {
            it("replaces placeholders with document stats") {
                let doc = TextDocument()
                doc.content = ["Hello world", "Swift is great", "Last line"]
                doc.totalLines = doc.content.count
                // Create layer using live document factory
                let layer = OverlayFactory.makeStatisticsOverlay(document: doc, rows: Settings.rows - 2, cols: Settings.cols)

                // Convert layer rows into strings to search for values
                let lines = layer.grid.map { rowToString($0) }

                // Expected values
                let expectedLines = doc.content.count
                let expectedChars = doc.content.joined(separator: "\n").count
                let expectedWords = doc.content.reduce(0) { acc, line in
                    acc + countWords(in: line)
                }

                // Check presence of values in overlay text
                expect(lines.joined(separator: "\n")).to(contain("\(expectedLines)"))
                expect(lines.joined(separator: "\n")).to(contain("\(expectedWords)"))
                expect(lines.joined(separator: "\n")).to(contain("\(expectedChars)"))
            }
        }
    }
}
