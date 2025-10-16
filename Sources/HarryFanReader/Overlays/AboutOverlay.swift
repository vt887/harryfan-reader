//
//  AboutOverlay.swift
//  harryfan-reader
//
//  Created by @vt887 on 10/15/25.
//

import SwiftUI

extension OverlayFactory {
    /// Create a centered about overlay ScreenLayer
    static func makeAboutOverlay(rows: Int = Settings.rows - 2, cols: Int = Settings.cols, fgColor: Color = Colors.theme.foreground) -> ScreenLayer {
        var layer = ScreenLayer(rows: rows, cols: cols)
        let message = Messages.aboutMessage
        let lines = message.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        let totalLines = lines.count
        let verticalPadding = max(0, (rows - totalLines) / 2)
        for (i, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let padding = max(0, (cols - trimmed.count) / 2)
            let startCol = padding
            for (j, char) in trimmed.enumerated() {
                let row = verticalPadding + i
                let col = startCol + j
                if row < rows, col < cols {
                    layer[row, col] = ScreenCell(char: char, fgColor: fgColor, bgColor: nil)
                }
            }
        }
        return layer
    }

    /// Action bar items to show when the About overlay is active
    static func aboutActionBarItems(cols _: Int = Settings.cols) -> [String] {
        [
            "Help", Settings.wordWrapLabel, "Open", "Search", "Goto",
            "Bookm", "Start", "End", "Menu", "Quit",
        ]
    }
}

// Top-level wrapper function for use by other modules
func aboutActionBarItems(cols: Int = Settings.cols) -> [String] {
    OverlayFactory.aboutActionBarItems(cols: cols)
}

// Top-level helper struct to expose per-overlay ActionBar items
enum AboutOverlay {
    static func actionBarItems(cols: Int = Settings.cols) -> [String] {
        OverlayFactory.aboutActionBarItems(cols: cols)
    }
}
