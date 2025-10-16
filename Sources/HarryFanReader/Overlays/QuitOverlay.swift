//
//  QuitOverlay.swift
//  harryfan-reader
//
//  Created by @vt887 on 10/15/25.
//

import SwiftUI

extension OverlayFactory {
    /// Create a centered quit overlay ScreenLayer
    static func makeQuitOverlay(rows: Int = Settings.rows - 2, cols: Int = Settings.cols, fgColor: Color = Colors.theme.foreground) -> ScreenLayer {
        var layer = ScreenLayer(rows: rows, cols: cols)
        let message = Messages.quitMessage
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

    /// Action bar items to show when the Quit overlay is active
    static func quitActionBarItems(cols _: Int = Settings.cols) -> [String] {
        [
            "", "", "", "", "",
            "", "", "", "", "Quit",
        ]
    }
}

// Top-level wrapper function for use by other modules
func quitActionBarItems(cols: Int = Settings.cols) -> [String] {
    OverlayFactory.quitActionBarItems(cols: cols)
}

// Top-level helper struct to expose per-overlay ActionBar items
enum QuitOverlay {
    static func actionBarItems(cols: Int = Settings.cols) -> [String] {
        OverlayFactory.quitActionBarItems(cols: cols)
    }
}
