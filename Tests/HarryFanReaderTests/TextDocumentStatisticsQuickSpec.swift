//
//  TextDocumentStatisticsQuickSpec.swift
//  HarryFanReaderTests
//
//  Created by @vt887 on 10/25/25.
//

@testable import HarryFanReader
import Nimble
import Quick

final class TextDocumentStatisticsQuickSpec: QuickSpec {
    override class func spec() {
        describe("TextDocument.statistics") {
            it("computes correct stats for simple content") {
                let doc = TextDocument()
                doc.content = ["Hello world", "Swift is great", "Last line"]
                doc.totalLines = doc.content.count

                let stats = doc.statistics()

                expect(stats.totalLines).to(equal(3))
                expect(stats.totalWords).to(equal(7))
                // 'joined(separator: "\n")' adds 2 newline chars for 3 lines -> totalCharacters = sum(lengths)+2
                expect(stats.totalCharacters).to(equal(36))
                expect(stats.averageLineLength).to(equal(11))
                expect(stats.longestLineLength).to(equal(14))
                expect(stats.shortestLineLength).to(equal(9))
                expect(stats.byteSize).to(equal(36))
            }

            it("returns zeros for empty document") {
                let doc = TextDocument()
                doc.content = []
                doc.totalLines = 0

                let stats = doc.statistics()

                expect(stats.totalLines).to(equal(0))
                expect(stats.totalWords).to(equal(0))
                expect(stats.totalCharacters).to(equal(0))
                expect(stats.averageLineLength).to(equal(0))
                expect(stats.longestLineLength).to(equal(0))
                expect(stats.shortestLineLength).to(equal(0))
                expect(stats.byteSize).to(equal(0))
            }
        }
    }
}
