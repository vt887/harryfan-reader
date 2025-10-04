//
//  BottomBar.swift
//  harryfan-reader
//
//  Created by @vt887 on 9/25/25.

import SwiftUI

let bottomBarItems = [
    "Help", "Wrap", "Open", "Search", "Goto",
    "Bookm", "Start", "End", "Menu", "Quit",
]

// View for displaying the bottom bar in the app
struct BottomBar: View {
    // Observed document model for the bottom bar
    @ObservedObject var document: TextDocument
    // Font manager environment object
    @EnvironmentObject var fontManager: FontManager

    // Main view body rendering the bottom bar
    var body: some View {
        ScreenView(document: document,
                   contentToDisplay: document.getMenuBarText(bottomBarItems),
                   displayRows: 1,
                   rowOffset: document.rows - 1,
                   backgroundColor: Colors.theme.menuBarBackground,
                   fontColor: Colors.theme.menuBarForeground,
                   overlayLayers: .constant([]),
                   overlayOpacities: .constant([:]))
    }
}
