//
//  TextFormatter.swift
//  harryfan-reader
//
//  Created by @vt887 on 10/12/25.
//

import Foundation

// Utility class for formatting text in the app
class TextFormatter {
    // Calculate percent position (0..100) based on the bottom visible line
    // Example: if topLine=0 and 22 lines visible, bottomLine=22, so 22/30*100 = 73%
    // If topLine=1 and 22 lines visible, bottomLine=23, so 23/30*100 = 77%
    private static func percent(topLine: Int, visibleLines: Int, totalLines: Int) -> Int {
        // Avoid division by zero for empty documents
        guard totalLines > 0 else { return 0 }
        // Special case: if document fits entirely on screen, show 100%
        if totalLines <= (Settings.rows - 2) {
            return 100
        }
        // Calculate the bottom visible line (1-indexed for percentage calculation)
        let bottomLine = topLine + visibleLines
        // Calculate percentage based on how much of the file is visible up to the bottom line
        let p = ((Double(bottomLine) / Double(totalLines)) * 100.0).rounded()
        return max(0, min(100, Int(p)))
    }

    // Returns the formatted title bar text
    static func getTitleBarText(appName: String, fileName: String, totalLines: Int, currentLine: Int, totalCols: Int) -> String {
        // Percent based on bottom visible line ratio
        // currentLine represents topLine (the first visible line in viewport)
        let percent = percent(topLine: currentLine, visibleLines: Settings.visibleLines, totalLines: totalLines)
        let space = getPercentSpacing(percent)
        // Updated status text: remove current line number, show total lines only
        let statusText = "Lines: \(totalLines) " + String(repeating: " ", count: space) + "\(percent)%"
        let leftPad = " "
        let rightPad = " "
        let separator = " │ "
        let minTitleLen = 10
        var displayFileName = fileName
        let emptyFile = fileName.isEmpty
        let title: String
        let left = leftPad + appName + separator

        if emptyFile {
            title = left.padding(toLength: totalCols, withPad: " ", startingAt: 0)
        } else {
            let usedWidth = appName.count + separator.count + statusText.count + leftPad.count + rightPad.count
            let availableWidth = max(minTitleLen, totalCols - usedWidth)
            // Truncate the file name if it exceeds the available width, adding "..." at the end
            if fileName.count > availableWidth {
                displayFileName = String(fileName.prefix(availableWidth - 3)) + "..."
            }
            let left = left + displayFileName
            let paddedLeft = left.padding(toLength: totalCols - statusText.count - rightPad.count, withPad: " ", startingAt: 0)
            title = paddedLeft + statusText + rightPad
        }
        DebugLogger.log("TitleBar result: '\(title)'")
        return title
    }

    // Returns the formatted menu bar text
    static func getActionBarText(menuItems: [String], cols: Int) -> String {
        let menuBarString = menuItems.enumerated().map { index, item in
            let itemText = " \(index + 1)\(item)" // Add leading space before number
            return itemText.padding(toLength: 8, withPad: " ", startingAt: 0)
        }.joined(separator: "")
        let result = menuBarString.padding(toLength: cols, withPad: " ", startingAt: 0)
        DebugLogger.log("ActionBar result: '\(result)'")
        return result
    }

    // Helper function to get spacing for percent display
    private static func getPercentSpacing(_ percent: Int) -> Int {
        if percent < 10 {
            2
        } else if percent < 100 {
            1
        } else {
            0
        }
    }
}
