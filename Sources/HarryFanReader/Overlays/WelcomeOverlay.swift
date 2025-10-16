// WelcomeOverlay.swift
// Generated: separated welcome overlay into its own file

import SwiftUI

extension OverlayFactory {
    /// Create a centered welcome overlay ScreenLayer
    static func makeWelcomeOverlay(rows: Int = Settings.rows - 2, cols: Int = Settings.cols, fgColor: Color = Colors.theme.foreground) -> ScreenLayer {
        var layer = ScreenLayer(rows: rows, cols: cols)
        let message = Messages.welcomeMessage
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

    /// Action bar items to show when the Welcome overlay is active
    static func welcomeActionBarItems(cols: Int = Settings.cols) -> [String] {
        [
            "Help", Settings.wordWrapLabel, "Open", "Search", "Goto",
            "Bookm", "Start", "End", "Menu", "Quit",
        ]
    }
}

// Top-level wrapper function for use by other modules
func welcomeActionBarItems(cols: Int = Settings.cols) -> [String] {
    OverlayFactory.welcomeActionBarItems(cols: cols)
}

// Top-level helper struct to expose per-overlay ActionBar items
struct WelcomeOverlay {
    static func actionBarItems(cols: Int = Settings.cols) -> [String] {
        OverlayFactory.welcomeActionBarItems(cols: cols)
    }
}
