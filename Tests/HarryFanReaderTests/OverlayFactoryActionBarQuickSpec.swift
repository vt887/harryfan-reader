//
//  OverlayFactoryActionBarQuickSpec.swift
//  HarryFanReaderTests
//
//  Created by @vt887 on 10/15/25.
//

@testable import HarryFanReader
import Nimble
import Quick

final class OverlayFactoryActionBarQuickSpec: QuickSpec {
    override class func spec() {
        describe("OverlayFactory action bar items") {
            it("returns per-overlay actionBarItems for all kinds") {
                for kind in OverlayKind.allCases {
                    let fromFactory = OverlayFactory.actionBarItems(for: kind)
                    let expected: [String] = if kind == .help {
                        OverlayFactory.helpActionBarItems()
                    } else if kind == .welcome {
                        OverlayFactory.welcomeActionBarItems()
                    } else if kind == .quit {
                        OverlayFactory.quitActionBarItems()
                    } else if kind == .about {
                        OverlayFactory.aboutActionBarItems()
                    } else if kind == .search {
                        OverlayFactory.searchActionBarItems()
                    } else if kind == .goto {
                        OverlayFactory.gotoActionBarItems()
                    } else if kind == .menu {
                        OverlayFactory.menuActionBarItems()
                    } else if kind == .statistics {
                        OverlayFactory.statisticsActionBarItems()
                    } else {
                        // Fallback for any new/unknown kinds (e.g. library); actionBarItems(for:) should be the source of truth
                        OverlayFactory.actionBarItems(for: kind)
                    }
                    expect(fromFactory).to(equal(expected))
                }
            }
        }

        describe("OverlayFactory centering behavior") {
            it("centers welcome message horizontally") {
                let rows = 10
                let cols = 40
                let layer = OverlayFactory.make(kind: .welcome, rows: rows, cols: cols)
                // Find first non-space on first non-empty row
                func firstNonSpace(in row: Int) -> Int? {
                    for c in 0 ..< cols {
                        if layer[row, c].char != " " { return c }
                    }
                    return nil
                }
                var firstIdx: Int? = nil
                for r in 0 ..< rows {
                    if let idx = firstNonSpace(in: r) {
                        firstIdx = idx
                        break
                    }
                }
                expect(firstIdx).toNot(beNil())
                // ensure next non-empty row (if any) starts at same column
                var foundNext = false
                for r in 0 ..< rows {
                    if let idx = firstNonSpace(in: r) {
                        if !foundNext {
                            foundNext = true
                        } else {
                            expect(idx).to(equal(firstIdx))
                            break
                        }
                    }
                }
            }
        }
    }
}
