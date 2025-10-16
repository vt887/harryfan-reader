// GotoOverlay.swift
// harryfan-reader
//
// Created by automated change on 10/16/25.

import SwiftUI

extension OverlayFactory {
    /// Create a centered goto overlay ScreenLayer
    static func makeGotoOverlay(rows: Int = Settings.rows - 2, cols: Int = Settings.cols, fgColor: Color = Colors.theme.foreground) -> ScreenLayer {
        var layer = ScreenLayer(rows: rows, cols: cols)
        let message = Messages.gotoMessage
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

    /// Action bar items to show when the Goto overlay is active
    static func gotoActionBarItems(cols _: Int = Settings.cols) -> [String] {
        [
            "Close", "Goto", "Line#", "Menu", "Open", "Quit", "", "", "", "",
        ]
    }
}

// Top-level wrapper function for use by other modules
func gotoActionBarItems(cols: Int = Settings.cols) -> [String] {
    OverlayFactory.gotoActionBarItems(cols: cols)
}

// Top-level helper struct to expose per-overlay ActionBar items
enum GotoOverlay {
    static func actionBarItems(cols: Int = Settings.cols) -> [String] {
        OverlayFactory.gotoActionBarItems(cols: cols)
    }
}
