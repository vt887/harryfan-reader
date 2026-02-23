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

    // Make this a computed property so it always reflects current Settings (e.g. wordWrapLabel)
    static var defaultMenuItems: [String] {
        [
            "Help", Settings.wordWrapLabel, "Open", "Search", "Goto",
            "Bookm", "Start", "End", "Menu", "Quit",
        ]
    }

    // Prefer overlay-provided action bar items when an overlay is active.
    var menuItems: [String] {
        Self.defaultMenuItems
    }

    // Main view body rendering the menu bar
    var body: some View {
        ScreenView(document: document,
                   contentToDisplay: TextFormatter.getActionBarText(menuItems: menuItems, cols: Settings.cols),
                   displayRows: 1,
                   rowOffset: document.rows - 1,
                   backgroundColor: Colors.theme.menuBarBackground,
                   fontColor: Colors.theme.menuBarForeground,
                   tapHandler: { col, _, _ in
                       guard Settings.useMouse else { return }
                       // Each menu item is padded to 8 columns in TextFormatter.getActionBarText
                       let index = max(0, min(menuItems.count - 1, col / 8))
                       DebugLogger.log("ActionBar tapped: col=\(col), index=\(index)")
                   },
                   overlayLayers: .constant([]),
                   overlayOpacities: .constant([:]))
    }
}
