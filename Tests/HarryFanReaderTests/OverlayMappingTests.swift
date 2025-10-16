@testable import HarryFanReader
import XCTest

final class OverlayMappingTests: XCTestCase {
    func testOverlayKindToActiveOverlayRoundtrip() {
        for kind in OverlayKind.allCases {
            let active = kind.activeOverlay
            XCTAssertEqual(active.overlayKind, kind, "Roundtrip mapping failed for \(kind)")
        }
    }

    func testActiveOverlayNoneHasNilOverlayKind() {
        XCTAssertNil(ActiveOverlay.none.overlayKind)
    }
}
