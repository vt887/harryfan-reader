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
    // Main test entry point for OverlayFactory action bar and centering behavior
    override class func spec() {
        describe("OverlayFactory action bar items") {
            it("returns per-overlay actionBarItems for all kinds") {
                Self.testActionBarItemsForAllKinds()
            }
        }

        describe("OverlayFactory centering behavior") {
            it("centers welcome message horizontally") {
                Self.testCentersWelcomeMessage()
            }
        }
    }

    // Tests that OverlayFactory returns correct action bar items for all overlay kinds
    private static func testActionBarItemsForAllKinds() {
        for kind in OverlayKind.allCases {
            let fromFactory = OverlayFactory.actionBarItems(for: kind)
            let expected: [String] = expectedActionBarItems(for: kind)
            expect(fromFactory).to(equal(expected))
        }
    }

    // Returns the expected action bar items for a given overlay kind
    private static func expectedActionBarItems(for kind: OverlayKind) -> [String] {
        switch kind {
        case .help: OverlayFactory.helpActionBarItems()
        case .welcome: OverlayFactory.welcomeActionBarItems()
        case .quit: OverlayFactory.quitActionBarItems()
        case .about: OverlayFactory.aboutActionBarItems()
        case .search: OverlayFactory.searchActionBarItems()
        case .goto: OverlayFactory.gotoActionBarItems()
        case .menu: OverlayFactory.menuActionBarItems()
        case .statistics: OverlayFactory.statisticsActionBarItems()
        default:
            // Fallback for any new/unknown kinds (e.g. library); actionBarItems(for:) should be the source of truth
            OverlayFactory.actionBarItems(for: kind)
        }
    }

    // Tests that the welcome message is horizontally centered in the overlay
    private static func testCentersWelcomeMessage() {
        let rows = 10
        let cols = 40
        let layer = OverlayFactory.make(kind: .welcome, rows: rows, cols: cols)
        let firstIdx = firstNonSpaceColumn(in: layer, rows: rows, cols: cols)
        expect(firstIdx).toNot(beNil())
        // ensure next non-empty row (if any) starts at same column
        var foundFirst = false
        for r in 0 ..< rows {
            if let idx = firstNonSpaceColumn(in: layer, row: r, cols: cols) {
                if !foundFirst {
                    foundFirst = true
                } else {
                    expect(idx).to(equal(firstIdx))
                    break
                }
            }
        }
    }

    // Returns the first non-space column index in the overlay, searching all rows
    private static func firstNonSpaceColumn(in layer: ScreenLayer, rows: Int, cols: Int) -> Int? {
        for r in 0 ..< rows {
            if let idx = firstNonSpaceColumn(in: layer, row: r, cols: cols) {
                return idx
            }
        }
        return nil
    }

    // Returns the first non-space column index in a specific row
    private static func firstNonSpaceColumn(in layer: ScreenLayer, row: Int, cols: Int) -> Int? {
        for c in 0 ..< cols {
            if layer[row, c].char != " " { return c }
        }
        return nil
    }
}
