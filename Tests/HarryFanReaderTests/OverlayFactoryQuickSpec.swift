@testable import HarryFanReader
import Nimble
import Quick

final class OverlayFactoryQuickSpec: QuickSpec {
    override class func spec() {
        describe("OverlayFactory about overlay centering") {
            it("places the top border and other lines at the same horizontal offset") {
                // Create the overlay layer for `.about`
                let layer = OverlayFactory.make(kind: .about, rows: Settings.rows - 2, cols: Settings.cols)

                // Helper to find first non-space column index for a given row (returns nil if none)
                func firstNonSpaceIndex(in row: Int) -> Int? {
                    for col in 0 ..< Settings.cols {
                        if layer[row, col].char != " " {
                            return col
                        }
                    }
                    return nil
                }

                // Find first three non-empty rows (they should represent the box border and next lines)
                var nonEmptyRows: [Int] = []
                for r in 0 ..< layer.grid.count {
                    if let _ = firstNonSpaceIndex(in: r) {
                        nonEmptyRows.append(r)
                        if nonEmptyRows.count >= 3 { break }
                    }
                }

                expect(nonEmptyRows.count).to(beGreaterThanOrEqualTo(2))

                // Compute first non-space column for each found row
                let colsIndices = nonEmptyRows.compactMap { firstNonSpaceIndex(in: $0) }
                // Assert all found indices are equal (same left offset)
                if let first = colsIndices.first {
                    for idx in colsIndices {
                        expect(idx).to(equal(first))
                    }
                } else {
                    fail("No non-empty row found in overlay layer")
                }
            }
        }
    }
}
