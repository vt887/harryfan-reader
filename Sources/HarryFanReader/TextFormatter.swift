//
//  TextFormatter.swift
//  harryfan-reader
//
//  Created by @vt887 on 10/12/25.
//

import Foundation

// Utility class for formatting text in the app
class TextFormatter {
    // Returns the formatted title bar text
    static func getTitleBarText(appName: String, fileName: String, totalLines: Int, currentLine: Int, totalCols: Int) -> String {
        // Percent based on current cursor line position within total lines
        let percent: Int = {
            guard totalLines > 0 else { return 0 }
            let p = ((Double(currentLine + 1) / Double(totalLines)) * 100.0).rounded()
            return max(0, min(100, Int(p)))
        }()
        let space = getPercentSpacing(percent)
        // Updated status text: remove current line number, show total lines only
        let statusText = "Lines: \(totalLines)" + String(repeating: " ", count: space) + "\(percent)%"
        let leftPad = " "
        let rightPad = " "
        let separator = " │ "
        let minTitleLen = 10
        var displayFileName = fileName
        let emptyFile = fileName.isEmpty
        if !emptyFile {
            let usedWidth = appName.count + separator.count + statusText.count + leftPad.count + rightPad.count
            let availableWidth = max(minTitleLen, totalCols - usedWidth)
            if fileName.count > availableWidth {
                displayFileName = String(fileName.prefix(availableWidth - 3)) + "..."
            }
        }
        let title: String
        if emptyFile {
            let left = leftPad + appName + separator
            title = left.padding(toLength: totalCols, withPad: " ", startingAt: 0)
        } else {
            let left = leftPad + appName + separator + displayFileName
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
