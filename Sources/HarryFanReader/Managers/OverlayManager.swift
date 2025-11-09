//
//  OverlayManager.swift
//  harryfan-reader
//
//  Created by @vt887 on 11/9/25.
//

import Foundation
import SwiftUI

// ObservableObject that tracks requested overlay kinds and a simple opacity value.
// Designed to match the API expected by the rest of the codebase and tests.
final class OverlayManager: ObservableObject {
    // MARK: - Published state

    /// Published list of overlay kinds currently requested by other parts of the app.
    @Published private(set) var overlays: [OverlayKind] = []

    // MARK: - Internal state

    /// Simple opacity storage (0.0 .. 1.0). Tests may manipulate this via the helpers below.
    private var opacityValue: Double = 1.0

    // MARK: - Initialization

    init() {
        /*
         Intentionally left empty.

         Rationale:
         - The `OverlayManager` requires no runtime setup beyond the property defaults provided
           above (an empty overlay list and an initial opacity value). Keeping an explicit
           initializer makes the API self-documenting and allows tests or callers to rely on
           a stable, publicly-visible initializer if needed.
         - If future initialization logic is required (dependency injection, persisted state
           restoration, configuration), this initializer is the natural place to add it.
         - Leaving the initializer present (even empty) avoids implicit memberwise/init changes
           if more stored properties are added later and keeps call sites explicit.
        */
    }

    // MARK: - Overlay management

    /// Add an overlay kind if not already present (prevents duplicates).
    func addOverlay(_ kind: OverlayKind) {
        guard !overlays.contains(kind) else { return }
        overlays.append(kind)
    }

    /// Remove all entries for the given overlay kind.
    func removeOverlay(_ kind: OverlayKind) {
        overlays.removeAll { $0 == kind }
    }

    /// Remove all overlays.
    func removeAll() {
        overlays.removeAll()
    }

    /// Remove only help overlays (used by several places in the codebase).
    func removeHelpOverlay() {
        overlays.removeAll { $0 == .help }
    }

    // MARK: - Opacity helpers (tests)

    /// Clamp and store an opacity value in the range 0.0 ... 1.0.
    func setOpacity(_ value: Double) {
        opacityValue = min(1.0, max(0.0, value))
    }

    func getOpacity() -> Double { opacityValue }
}
