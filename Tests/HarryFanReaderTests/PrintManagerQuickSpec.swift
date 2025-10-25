//
//  PrintManagerQuickSpec.swift
//  HarryFanReaderTests
//
//  Created by @vt887 on 10/25/25.
//

import AppKit
@testable import HarryFanReader
import Nimble
import Quick

final class PrintManagerQuickSpec: QuickSpec {
    override class func spec() {
        describe("PrintManager pagination") {
            it("returns 1 page for very short content") {
                let pm = PrintManager()
                let font = NSFont.monospacedSystemFont(ofSize: 10.0, weight: .regular)
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineBreakMode = .byWordWrapping
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .paragraphStyle: paragraphStyle,
                ]

                let printableWidth: CGFloat = 612.0 - 36.0 - 36.0
                let printableHeight: CGFloat = 792.0 - 36.0 - 36.0

                let shortText = "Hello, world!"
                let pages = pm.pagesForFullText(shortText, attrs: attrs, printableWidth: printableWidth, printableHeight: printableHeight)
                expect(pages).to(equal(1))
            }

            it("computes expected pages for many short lines") {
                let pm = PrintManager()
                let font = NSFont.monospacedSystemFont(ofSize: 10.0, weight: .regular)
                // Compute line height from font metrics (ascender - descender + leading)
                let lineHeight = font.ascender - font.descender + font.leading

                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineBreakMode = .byWordWrapping
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .paragraphStyle: paragraphStyle,
                ]

                let printableWidth: CGFloat = 612.0 - 36.0 - 36.0
                let printableHeight: CGFloat = 792.0 - 36.0 - 36.0

                // Create N lines of single-character content to avoid wrapping
                let numberOfLines = 2000
                let text = Array(repeating: "A", count: numberOfLines).joined(separator: "\n")

                // Expected pages based on simple line-count division
                let linesPerPage = max(1, Int(floor(printableHeight / lineHeight)))
                let expectedPages = Int(ceil(Double(numberOfLines) / Double(linesPerPage)))

                let pages = pm.pagesForFullText(text, attrs: attrs, printableWidth: printableWidth, printableHeight: printableHeight)
                // Allow a small tolerance (±1 page) since font metrics/layout rounding can vary across environments
                let diff = abs(pages - expectedPages)
                expect(diff).to(beLessThanOrEqualTo(1), description: "pages:\(pages) expected:\(expectedPages) diff:\(diff)")
            }
        }
    }
}
