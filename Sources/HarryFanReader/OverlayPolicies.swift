//
//  OverlayPolicies.swift
//  harryfan-reader
//
//  Created by @vt887 on 10/15/25.
//

import AppKit
import SwiftUI

struct OverlayAllowedActivities {
    /// specific key codes that will dismiss the overlay if pressed
    var dismissKeyCodes: Set<UInt16> = []
    /// whether any key should dismiss the overlay
    var allowAnyKeyToDismiss: Bool = false
    /// whether a secondary (right) click on the ActionBar is allowed to remove the overlay
    var allowActionBarSecondaryClick: Bool = true
}

enum OverlayPolicies {
    static func allowedActivities(for kind: OverlayKind) -> OverlayAllowedActivities {
        switch kind {
        case .welcome:
            // Welcome: dismiss on any key, action bar clicks not allowed
            return OverlayAllowedActivities(dismissKeyCodes: [], allowAnyKeyToDismiss: true, allowActionBarSecondaryClick: false)
        case .help:
            // Help: F1 and ESC dismisses (no other keys or action-bar secondary clicks)
            return OverlayAllowedActivities(dismissKeyCodes: [KeyCode.f1, KeyCode.escape], allowAnyKeyToDismiss: false, allowActionBarSecondaryClick: true)
        case .quit:
            // Quit overlay: ESC or 'n' cancels, 'y' confirms. Allow action-bar secondary to hide.
            return OverlayAllowedActivities(dismissKeyCodes: [KeyCode.escape, KeyCode.yKey, KeyCode.nKey], allowAnyKeyToDismiss: false, allowActionBarSecondaryClick: true)
        case .about:
            // About: dismiss on ESC only
            return OverlayAllowedActivities(dismissKeyCodes: [KeyCode.escape], allowAnyKeyToDismiss: false, allowActionBarSecondaryClick: false)
        }
    }

    // Use centralized KeyCode enum defined in KeyCodes.swift
}
