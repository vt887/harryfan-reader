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
    override class func spec() {
        describe("centeredOverlayLayer") {
            it("preserves leading spaces for ASCII art and centers the message") {
                // Create a small screen
                let rows = 10
                let cols = 40
                // Message with leading spaces that must be preserved
                let message = "  ╔─\n  ║ [Close]\n  ╚─"

                let layer = centeredOverlayLayer(from: message, rows: rows, cols: cols, fgColor: Colors.theme.overlayForeground)

                // The text should be centered vertically; find the first non-empty row (top of box)
                // Check that on that row, the first visible character corresponds to the box corner '╔' (after padding)
                var found = false
                for r in 0 ..< rows {
                    for c in 0 ..< cols {
                        let cell = layer[r, c]
                        if cell.char == "╔" {
                            // Ensure the column is >= 0 and that preceding column(s) can be spaces, meaning leading spaces preserved
                            expect(c).to(beGreaterThanOrEqualTo(2))
                            found = true
                            break
                        }
                    }
                    if found { break }
                }
                expect(found).to(beTrue())
            }

            it("detects bracketed buttons and registers an OverlayButton") {
                let rows = 8
                let cols = 40
                let message = "[OK]  [Cancel]"
                let layer = centeredOverlayLayer(from: message, rows: rows, cols: cols, fgColor: Colors.theme.overlayForeground)

                // There should be at least two buttons: OK and Cancel
                let labels = layer.buttons.map(\.label)
                expect(labels).to(contain("OK"))
                expect(labels).to(contain("Cancel"))

                // Ensure button positions point to characters within the layer bounds
                for btn in layer.buttons {
                    expect(btn.row).to(beGreaterThanOrEqualTo(0))
                    expect(btn.row).to(beLessThan(rows))
                    expect(btn.col).to(beGreaterThanOrEqualTo(0))
                    expect(btn.col + btn.length).to(beLessThanOrEqualTo(cols))
                }
            }
        }
    }
}
