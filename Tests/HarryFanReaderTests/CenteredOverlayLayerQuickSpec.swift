//
//  CenteredOverlayLayerQuickSpec.swift
//  HarryFanReaderTests
//
//  Created by @vt887 on 10/25/25.
//

@testable import HarryFanReader
import Nimble
import Quick

final class CenteredOverlayLayerQuickSpec: QuickSpec {
    // Main test: verifies centeredOverlayLayer behavior
    override class func spec() {
        describe("centeredOverlayLayer") {
            it("preserves leading spaces for ASCII art and centers the message") {
                Self.testPreservesLeadingSpacesAndCenters()
            }

            it("detects bracketed buttons and registers an OverlayButton") {
                Self.testDetectsBracketedButtons()
            }
        }
    }

    // Test that leading spaces are preserved and message is centered
    private static func testPreservesLeadingSpacesAndCenters() {
        let rows = 10
        let cols = 40
        let message = "  ╔─\n  ║ [Close]\n  ╚─"
        let layer = centeredOverlayLayer(from: message, rows: rows, cols: cols, fgColor: Colors.theme.overlayForeground)
        var found = false
        for r in 0 ..< rows {
            for c in 0 ..< cols {
                let cell = layer[r, c]
                if cell.char == "╔" {
                    expect(c).to(beGreaterThanOrEqualTo(2))
                    found = true
                    break
                }
            }
            if found { break }
        }
        expect(found).to(beTrue())
    }

    // Test that bracketed buttons are detected and registered as OverlayButton
    private static func testDetectsBracketedButtons() {
        let rows = 8
        let cols = 40
        let message = "[OK]  [Cancel]"
        let layer = centeredOverlayLayer(from: message, rows: rows, cols: cols, fgColor: Colors.theme.overlayForeground)
        let labels = layer.buttons.map(\.label)
        expect(labels).to(contain("OK"))
        expect(labels).to(contain("Cancel"))
        for btn in layer.buttons {
            expect(btn.row).to(beGreaterThanOrEqualTo(0))
            expect(btn.row).to(beLessThan(rows))
            expect(btn.col).to(beGreaterThanOrEqualTo(0))
            expect(btn.col + btn.length).to(beLessThanOrEqualTo(cols))
        }
    }
}
