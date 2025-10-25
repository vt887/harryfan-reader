//
//  OverlayFactoryStatisticsQuickSpec.swift
//  HarryFanReaderTests
//
//  Created by @vt887 on 10/15/25.
//

@testable import HarryFanReader
import Nimble
import Quick

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
                let lines = layer.grid.map { row in
                    String(row.map(\.char))
                }

                // Expected values
                let expectedLines = doc.content.count
                let expectedChars = doc.content.joined(separator: "\n").count
                let expectedWords = doc.content.reduce(0) { $0 + $1.split { $0.isWhitespace }.count }

                // Check presence of values in overlay text
                expect(lines.joined(separator: "\n")).to(contain("\(expectedLines)"))
                expect(lines.joined(separator: "\n")).to(contain("\(expectedWords)"))
                expect(lines.joined(separator: "\n")).to(contain("\(expectedChars)"))
            }
        }
    }
}
