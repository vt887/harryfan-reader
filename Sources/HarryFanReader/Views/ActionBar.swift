//
//  ActionBar.swift
//  harryfan-reader
//
//  Created by @vt887 on 9/25/25.
//

import SwiftUI

// View for displaying the menu bar in the app
struct ActionBar: View {
    // Observed document model for the menu bar
    @ObservedObject var document: TextDocument
    // Font manager environment object
    @EnvironmentObject var fontManager: FontManager
    // Overlay manager to check active overlays and enforce allowed actions
    @EnvironmentObject var overlayManager: OverlayManager

    // Computed menu items to reflect current wordWrap state
    var menuItems: [String] {
        // If an overlay is active, prefer the overlay-specific action bar items
        if let top = overlayManager.overlays.last {
            return OverlayFactory.actionBarItems(for: top)
        }

        // Default menu items
        return [
            "Help", Settings.wordWrapLabel, "Open", "Search", "Goto",
            "Bookm", "Start", "End", "Menu", "Quit",
        ]
    }

    // Main view body rendering the menu bar
    var body: some View {
        ScreenView(document: document,
                   contentToDisplay: TextFormatter.getActionBarText(menuItems: menuItems, cols: Settings.cols),
                   displayRows: 1,
                   rowOffset: document.rows - 1,
                   backgroundColor: Colors.theme.menuBarBackground,
                   fontColor: Colors.theme.menuBarForeground,
                   tapHandler: { col, _, isSecondary in
                       // Each menu item is padded to 8 columns in TextFormatter.getActionBarText
                       let index = max(0, min(menuItems.count - 1, col / 8))
                       DebugLogger.log("ActionBar tapped: col=\(col), index=\(index), secondary=\(isSecondary)")
                       switch index {
                       case 0: // Help
                           DispatchQueue.main.async {
                               if isSecondary {
                                   // If help overlay is active, ignore secondary clicks (Help must be dismissed with F1)
                                   if overlayManager.overlays.contains(.help) {
                                       DebugLogger.log("ActionBar: secondary-click on Help ignored because Help overlay is active (F1 required to dismiss)")
                                   } else {
                                       DebugLogger.log("ActionBar: secondary-click — posting removeHelpOverlay")
                                       NotificationCenter.default.post(name: .removeHelpOverlay, object: nil)
                                   }
                               } else {
                                   DebugLogger.log("ActionBar: posting toggleHelpOverlay")
                                   NotificationCenter.default.post(name: .toggleHelpOverlay, object: nil)
                               }
                           }
                       default:
                           // All other buttons are intentionally disabled (no-op)
                           DebugLogger.log("ActionBar: tapped disabled button at index=\(index)")
                       }
                   },
                   overlayLayers: .constant([]),
                   overlayOpacities: .constant([:]))
    }
}
