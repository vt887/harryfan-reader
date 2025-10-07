//
//  MenuBar.swift
//  harryfan-reader
//
//  Created by @vt887 on 9/25/25.
//

import SwiftUI

// View for displaying the menu bar in the app
struct MenuBar: View {
    // Observed document model for the menu bar
    @ObservedObject var document: TextDocument
    // Font manager environment object
    @EnvironmentObject var fontManager: FontManager

    // Computed menu items to reflect current wordWrap state
    var menuItems: [String] {
        [
            "Help", AppSettings.wordWrapLabel, "Open", "Search", "Goto",
            "Bookm", "Start", "End", "Menu", "Quit",
        ]
    }

    // Main view body rendering the menu bar
    var body: some View {
        ScreenView(document: document,
                   contentToDisplay: document.getMenuBarText(menuItems),
                   displayRows: 1,
                   rowOffset: document.rows - 1,
                   backgroundColor: Colors.theme.menuBarBackground,
                   fontColor: Colors.theme.menuBarForeground,
                   overlayLayers: .constant([]),
                   overlayOpacities: .constant([:]))
    }
}
