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
            // Welcome: allow ESC to dismiss the welcome overlay; action bar clicks not allowed
            OverlayAllowedActivities(dismissKeyCodes: [], allowAnyKeyToDismiss: true, allowActionBarSecondaryClick: false)
        case .help:
            // Help: F1 and ESC dismisses (no other keys or action-bar secondary clicks)
            OverlayAllowedActivities(dismissKeyCodes: [KeyCode.f1, KeyCode.escape], allowAnyKeyToDismiss: false, allowActionBarSecondaryClick: true)
        case .quit:
            // Quit overlay: ESC or 'n' cancels, 'y' confirms. Allow action-bar secondary to hide.
            OverlayAllowedActivities(dismissKeyCodes: [KeyCode.escape, KeyCode.yKey, KeyCode.nKey], allowAnyKeyToDismiss: false, allowActionBarSecondaryClick: true)
        case .about:
            // About: dismiss on ESC only
            OverlayAllowedActivities(dismissKeyCodes: [KeyCode.escape, KeyCode.f9], allowAnyKeyToDismiss: false, allowActionBarSecondaryClick: false)
        case .statistics:
            // Statistics: dismiss on ESC only, don't allow action-bar secondary clicks
            OverlayAllowedActivities(dismissKeyCodes: [], allowAnyKeyToDismiss: true, allowActionBarSecondaryClick: false)
        case .menu:
            // Quit overlay: ESC or 'n' cancels, 'y' confirms. Allow action-bar secondary to hide.
            OverlayAllowedActivities(dismissKeyCodes: [KeyCode.escape, KeyCode.yKey, KeyCode.nKey], allowAnyKeyToDismiss: false, allowActionBarSecondaryClick: true)
        case .search:
            // About: dismiss on ESC only
            OverlayAllowedActivities(dismissKeyCodes: [KeyCode.escape], allowAnyKeyToDismiss: false, allowActionBarSecondaryClick: true)
        case .goto:
            // About: dismiss on ESC only
            OverlayAllowedActivities(dismissKeyCodes: [KeyCode.escape], allowAnyKeyToDismiss: false, allowActionBarSecondaryClick: true)
        }
    }
}
