//
//  TextDocument.swift
//  harryfan-reader
//
//  Created by @vt887 on 9/1/25.
//

import Foundation
import SwiftUI

// Observable object representing a text document
class TextDocument: ObservableObject {
    @Published var content: [String] = []
    @Published var currentLine: Int = 0
    @Published var totalLines: Int = 0
    @Published var encoding: String = "Unknown"
    @Published var fileName: String = ""
    @Published var removeEmptyLines: Bool = true
    @Published var wordWrap: Bool = AppSettings.wordWrap
    @Published var wrapWidth: Int = AppSettings.wrapWidth
    @Published var shouldShowQuitMessage: Bool = AppSettings.shouldShowQuitMessage
    @Published var rows: Int = AppSettings.rows
    // Top visible line of viewport
    @Published var topLine: Int = 0
    // Fixed cursor row (highlight). For now we keep it at 0 (top of viewport)
    let fixedCursorRow: Int = 0

    private var originalData: Data?

    // Returns the quit message string
    var quitMessage: String { Messages.quitMessage }

    // Loads the welcome text into the document
    func loadWelcomeText() {
        content = splitLines(Messages.centeredWelcomeMessage(screenWidth: AppSettings.cols, screenHeight: AppSettings.rows - 2))
        totalLines = content.count
        topLine = 0
        currentLine = 0
    }

    // Opens a file and loads its content
    func openFile(at url: URL) {
        do {
            DebugLogger.log("Opening file: \(url.path)")
            fileName = url.lastPathComponent
            originalData = try Data(contentsOf: url)
            guard let data = originalData else {
                return
            }

            let decodedString = decodeCP866(from: data)
            let rawLines = cleanLines(splitLines(decodedString))
            content = wrapLines(rawLines)
            totalLines = content.count
            DebugLogger.log("Opened file '\(fileName)' size=\(data.count) bytes lines=\(totalLines) encoding=CP866")
            // Initialize viewport at top
            topLine = 0
            currentLine = 0
        } catch {
            DebugLogger.log("Error opening file: \(error)")
        }
    }

    // Returns the formatted title bar text
    func getTitleBarText() -> String {
        let appName = AppSettings.appName
        let totalCols = AppSettings.cols
        let emptyFile = fileName.isEmpty
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
    func getMenuBarText(_ items: [String]) -> String {
        let menuBarString = items.enumerated().map { index, item in
            let itemText = " \(index + 1)\(item)" // Add leading space before number
            return itemText.padding(toLength: 8, withPad: " ", startingAt: 0)
        }.joined(separator: "")
        let result = menuBarString.padding(toLength: AppSettings.cols, withPad: " ", startingAt: 0)
        DebugLogger.log("MenuBar result: '\(result)'")
        return result
    }

    // Decodes CP866 encoded data to a string
    private func decodeCP866(from data: Data) -> String {
        var result = String.UnicodeScalarView()
        for byte in data {
            let scalar = UnicodeScalar(unicodePoints[Int(byte)])!
            result.append(scalar)
        }
        return String(result)
    }

    // Wraps lines according to the wrap width
    private func wrapLines(_ lines: [String]) -> [String] {
        guard wordWrap else { return lines }

        var wrappedLines: [String] = []

        for line in lines {
            if line.count <= wrapWidth {
                wrappedLines.append(line)
            } else {
                // Split long lines
                var currentLine = ""

                let words = line.components(separatedBy: " ")

                for word in words {
                    if currentLine.isEmpty {
                        currentLine = word
                    } else if currentLine.count + word.count + 1 <= wrapWidth {
                        currentLine += " " + word
                    } else {
                        // Current line is full, start a new one
                        if !currentLine.isEmpty {
                            wrappedLines.append(currentLine)
                        }
                        currentLine = word
                    }
                }

                // Add the last line
                if !currentLine.isEmpty {
                    wrappedLines.append(currentLine)
                }
            }
        }

        return wrappedLines
    }

    // Splits text into lines, handling line endings
    private func splitLines(_ text: String) -> [String] {
        // Handle different line ending formats properly
        // Replace \r\n with \n first, then split by \n
        let normalizedText = text.replacingOccurrences(of: "\r\n", with: "\n")
        return normalizedText.components(separatedBy: "\n")
    }

    // Cleans lines by removing excessive empty lines
    private func cleanLines(_ lines: [String]) -> [String] {
        if !removeEmptyLines {
            return lines
        }

        var result: [String] = []
        var consecutiveEmptyLines = 0

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmedLine.isEmpty {
                consecutiveEmptyLines += 1
                // Keep only one empty line for every 2 consecutive empty lines
                if consecutiveEmptyLines <= 1 {
                    result.append("")
                }
            } else {
                consecutiveEmptyLines = 0
                result.append(line)
            }
        }

        // Remove trailing empty lines
        while result.last?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true {
            result.removeLast()
        }

        return result
    }

    // Closes the currently open file
    func closeFile() {
        content = []
        currentLine = 0
        totalLines = 0
        encoding = "Unknown"
        fileName = ""
        originalData = nil
    }

    // Reloads the document with new settings
    func reloadWithNewSettings() {
        guard let data = originalData else {
            return
        }

        let decodedString = decodeCP866(from: data)
        let rawLines = cleanLines(splitLines(decodedString))
        content = wrapLines(rawLines)
        totalLines = content.count
        topLine = min(topLine, max(0, totalLines - 1))
        currentLine = topLine + fixedCursorRow
    }

    // Toggles word wrap and reloads content
    func toggleWordWrap() {
        wordWrap.toggle()
        DebugLogger.log("Word wrap toggled to: \(wordWrap)")
        reloadWithNewSettings()
    }

    // Navigates to a specific line in the document
    func gotoLine(_ line: Int) {
        guard totalLines > 0 else {
            return
        }
        let target = max(0, min(line - 1, totalLines - 1))
        // Show target line at top (cursor line)
        topLine = target
        currentLine = target
    }

    // Navigates to the start of the document
    func gotoStart() {
        topLine = 0; currentLine = 0
    }

    // Navigates to the end of the document
    func gotoEnd() {
        guard totalLines > 0 else {
            return
        }
        let displayRows = AppSettings.rows - 2
        // Move cursor to the very last line
        currentLine = totalLines - 1
        // Show the last page (so that the last line is visible at bottom)
        topLine = max(0, totalLines - displayRows)
    }

    // Scrolls up one page in the document
    func pageUp() {
        guard totalLines > 0 else {
            return
        }
        let pageStep = max(1, (AppSettings.rows - 2) - 2) // leave 2-line overlap
        currentLine = max(0, currentLine - pageStep)
        topLine = currentLine
    }

    // Scrolls down one page in the document
    func pageDown() {
        guard totalLines > 0 else {
            return
        }
        let pageStep = max(1, (AppSettings.rows - 2) - 2) // leave 2-line overlap
        currentLine = min(totalLines - 1, currentLine + pageStep)
        topLine = currentLine
    }

    // Scrolls up one line in the document
    func lineUp() {
        guard totalLines > 0 else {
            return
        }
        if topLine > 0 {
            topLine -= 1
            currentLine = topLine
        }
        // If already at top, do nothing
    }

    // Scrolls down one line in the document
    func lineDown() {
        guard totalLines > 0 else {
            return
        }
        let displayRows = AppSettings.rows - 2
        let bottomLine = min(totalLines - 1, topLine + displayRows - 1)
        if bottomLine < totalLines - 1 {
            topLine += 1
            currentLine = topLine
        }
        // If already at bottom, do nothing
    }

    // Searches for a query string in the document
    func search(_ query: String, direction: SearchDirection = .forward, caseSensitive: Bool = false) -> Int? {
        guard !query.isEmpty else {
            return nil
        }

        let searchQuery = caseSensitive ? query : query.lowercased()
        let lines = caseSensitive ? content : content.map { $0.lowercased() }
        var found: Int? = nil
        if direction == .forward {
            for index in (currentLine + 1) ..< lines.count where lines[index].contains(searchQuery) {
                found = index; break
            }
            if found == nil {
                for index in 0 ... currentLine where lines[index].contains(searchQuery) {
                    found = index; break
                }
            }
        } else {
            if currentLine > 0 {
                for index in stride(from: currentLine - 1, through: 0, by: -1) where lines[index].contains(searchQuery) {
                    found = index; break
                }
            }
            if found == nil {
                for index in stride(from: lines.count - 1, through: currentLine, by: -1) where lines[index].contains(searchQuery) {
                    found = index; break
                }
            }
        }
        if let idx = found {
            topLine = idx
            currentLine = idx
        }
        return found
    }

    // Returns the content of the current line
    func getCurrentLine() -> String {
        guard currentLine >= 0, currentLine < content.count else {
            return ""
        }
        return content[currentLine]
    }

    // Visible lines based on topLine (viewport)
    func getVisibleLines(displayRows: Int) -> [String] {
        guard totalLines > 0 else {
            return []
        }
        let top = min(max(0, topLine), max(0, totalLines - 1))
        if totalLines <= displayRows {
            return content
        }
        let end = min(totalLines, top + displayRows)
        return Array(content[top ..< end])
    }

    func getVisibleLines() -> [String] {
        getVisibleLines(displayRows: AppSettings.rows - 2)
    }

    // Removed obsolete topVisibleLine centering method.

    private func getPercentSpacing(_ percent: Int) -> Int {
        if percent < 10 {
            3
        } else if percent < 100 {
            2
        } else {
            1
        }
    }

    private func calculatePercent(bottomLine: Int, topLine: Int, totalLines: Int) -> Int {
        guard totalLines > 0 else {
            return 0
        }
        if bottomLine == totalLines - 1 {
            return 100
        }
        if topLine == 0 {
            return 0
        }
        return Int((Double(bottomLine + 1) / Double(totalLines)) * 100.0)
    }
}

// Enum for search direction in text document
enum SearchDirection {
    case forward
    case backward
}
