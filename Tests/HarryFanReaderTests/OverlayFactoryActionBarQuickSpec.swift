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
                let kinds: [OverlayKind] = [.help, .welcome, .quit, .about, .search, .goto, .menu]
                for kind in kinds {
                    let fromFactory = OverlayFactory.actionBarItems(for: kind)
                    switch kind {
                    case .help:
                        expect(fromFactory).to(equal(HelpOverlay.actionBarItems()))
                    case .welcome:
                        expect(fromFactory).to(equal(WelcomeOverlay.actionBarItems()))
                    case .quit:
                        expect(fromFactory).to(equal(QuitOverlay.actionBarItems()))
                    case .about:
                        expect(fromFactory).to(equal(AboutOverlay.actionBarItems()))
                    case .search:
                        expect(fromFactory).to(equal(SearchOverlay.actionBarItems()))
                    case .goto:
                        expect(fromFactory).to(equal(GotoOverlay.actionBarItems()))
                    case .menu:
                        expect(fromFactory).to(equal(MenuOverlay.actionBarItems()))
                    }
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
