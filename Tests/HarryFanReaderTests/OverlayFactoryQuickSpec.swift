@testable import HarryFanReader
import Nimble
import Quick

final class OverlayFactoryQuickSpec: QuickSpec {
    override class func spec() {
        describe("OverlayFactory about overlay centering") {
            it("places the top border and other lines at the same horizontal offset") {
                Self.testAboutOverlayLinesAligned()
            }
        }
    }

    // Checks that the about overlay's non-empty lines are horizontally aligned
    private static func testAboutOverlayLinesAligned() {
        let layer = OverlayFactory.make(kind: .about, rows: Settings.rows - 2, cols: Settings.cols)
        let nonEmptyRows = firstNNonEmptyRows(in: layer, n: 3)
        expect(nonEmptyRows.count).to(beGreaterThanOrEqualTo(2))
        let colsIndices = nonEmptyRows.compactMap { firstNonSpaceIndex(in: layer, row: $0) }
        if let first = colsIndices.first {
            for idx in colsIndices {
                expect(idx).to(equal(first))
            }
        } else {
            fail("No non-empty row found in overlay layer")
        }
    }

    // Returns the index of the first non-space character in a given row
    private static func firstNonSpaceIndex(in layer: ScreenLayer, row: Int) -> Int? {
        for col in 0 ..< Settings.cols {
            if layer[row, col].char != " " {
                return col
            }
        }
        return nil
    }

    // Returns the indices of the first n non-empty rows in the layer
    private static func firstNNonEmptyRows(in layer: ScreenLayer, n: Int) -> [Int] {
        var nonEmptyRows: [Int] = []
        for r in 0 ..< layer.grid.count {
            if let _ = firstNonSpaceIndex(in: layer, row: r) {
                nonEmptyRows.append(r)
                if nonEmptyRows.count >= n { break }
            }
        }
        return nonEmptyRows
    }
}
