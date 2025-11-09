//
//  OverlayManager.swift
//  harryfan-reader
//
//  Created to provide the missing OverlayManager type referenced across the app.
//

import Foundation
import SwiftUI

// ObservableObject that tracks requested overlay kinds and a simple opacity value.
// Designed to match the API expected by the rest of the codebase and tests.
final class OverlayManager: ObservableObject {
    // Published list of overlay kinds currently requested by other parts of the app.
    @Published private(set) var overlays: [OverlayKind] = []

    // Simple opacity storage (0.0 .. 1.0)
    private var opacityValue: Double = 1.0

    init() {}

    // Add an overlay kind if not already present (prevents duplicates)
    func addOverlay(_ kind: OverlayKind) {
        guard !overlays.contains(kind) else { return }
        overlays.append(kind)
    }

    // Remove all entries for the given overlay kind
    func removeOverlay(_ kind: OverlayKind) {
        overlays.removeAll { $0 == kind }
    }

    // Remove all overlays
    func removeAll() {
        overlays.removeAll()
    }

    // Remove only help overlays (used by several places in the codebase)
    func removeHelpOverlay() {
        overlays.removeAll { $0 == .help }
    }

    // Opacity helpers used by unit tests
    func setOpacity(_ value: Double) {
        opacityValue = min(1.0, max(0.0, value))
    }

    func getOpacity() -> Double { opacityValue }
}
