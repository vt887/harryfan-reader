//
//  Messages.swift
//  harryfan-reader
//
//  Created by @vt887 on 9/1/25.
//

import Foundation

// Enum for static app messages
enum Messages {
    // Keep templates separate so we can substitute placeholders when accessed
    private static let aboutTemplate = """
    ╔══════════════════ About ══════════════════╗
    ║              HarryFan Reader              ║
    ║            Version %version%              ║
    ║                  [Close]                  ║
    ╚═══════════════════════════════════════════╝
    """

    private static let welcomeTemplate = """
    ╔═════════════ HarryFan Reader ═════════════╗
    ║      Retro MS-DOS Style Text Viewer       ║
    ║             Version %version%             ║
    ╚═══════════════════════════════════════════╝
    """

    static let helpMessage = """
    ╔════════════════════════ Help ═════════════════════════╗
    ║  F1  - Help        Show/hide this help screen         ║
    ║  F2  - Word Wrap   Toggle word wrapping on/off        ║
    ║  F3  - Open File   Open a new text file               ║
    ║  F7  - Go Start    Jump to the beginning of the file  ║
    ║  F8  - Go End      Jump to the end of the file        ║
    ║  F10 - Quit        Exit the application               ║
    ╚═══════════════════════════════════════════════════════╝
    """

    static let quitMessage = """
    ╔═════════════════════ Quit ════════════════════╗
    ║        Thank you for using HarryFan Reader!   ║
    ║                   [Yes] [No]                  ║
    ╚═══════════════════════════════════════════════╝
    """

    static let searchMessage = """
    ╔════════════════════ Search ══════════════════════╗
    ║  Search for the string                           ║
    ║  xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx   ║
    ║  [Search] [Cancel]                               ║
    ╚══════════════════════════════════════════════════╝
    """

    static let gotoMessage = """
    ╔═════════════════════ Goto ═══════════════════════╗
    ║  Look for a line                                 ║
    ║  xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx   ║
    ║  [Go To] [Cancel]                                ║
    ╚══════════════════════════════════════════════════╝
    """

    static let menuMessage = """
    ╔══════════════════════ Menu ══════════════════════╗
    ║  Open File          F3                           ║
    ║  Search             F4                           ║
    ╚══════════════════════════════════════════════════╝
    """

    static let statisticsMessage = """
    ╔════════════════ Statistics ═════════════════╗
    ║  Total Lines: %totalLines%                  ║
    ║  Total Words: %totalWords%                  ║
    ║  Total Characters: %totalChars%             ║
    ║  File Size (bytes): %byteSize%              ║
    ║  Average Line Length: %avgLineLength%       ║
    ║  Longest Line Length: %longestLineLength%   ║
    ║  Shortest Line Length: %shortestLineLength% ║
    ╚═════════════════════════════════════════════╝
    """

    static let libraryMessage = """
    ╔════════════════ Library ═════════════════╗
    ║  No recent files                         ║
    ╚══════════════════════════════════════════╝
    """

    // Simple helper to substitute common placeholders in message templates
    private static func applyPlaceholders(_ template: String) -> String {
        var result = template
        result = result.replacingOccurrences(of: "%version%", with: ReleaseInfo.version)
        return result
    }

    // Public computed properties apply placeholders on access
    static var aboutMessage: String { applyPlaceholders(aboutTemplate) }
    static var welcomeMessage: String { applyPlaceholders(welcomeTemplate) }

    // Centers an already-filled multi-line message string horizontally and vertically.
    // This function assumes placeholders (like %version%) are already substituted in the input string.
    static func centeredMessage(_ message: String, screenWidth: Int, screenHeight: Int) -> String {
        let lines = message.components(separatedBy: "\n")
        let centeredLines = lines.map { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let totalPadding = max(0, screenWidth - trimmed.count)
            let leftPadding = totalPadding / 2
            let rightPadding = totalPadding - leftPadding
            let padLeft = String(repeating: " ", count: leftPadding)
            let padRight = String(repeating: " ", count: rightPadding)
            return padLeft + trimmed + padRight
        }
        let totalLines = centeredLines.count
        let verticalPadding = max(0, (screenHeight - totalLines) / 2)
        let emptyLine = String(repeating: " ", count: screenWidth)
        let topPadding = Array(repeating: emptyLine, count: verticalPadding)
        let bottomPadding = Array(repeating: emptyLine, count: screenHeight - totalLines - verticalPadding)
        return (topPadding + centeredLines + bottomPadding).joined(separator: "\n")
    }

    // Substitute placeholders (%name%) in `template` with corresponding values from `replacements`.
    // Replacement preserves the placeholder width by left-aligning the replacement text and
    // appending spaces after the value so characters to the right of the placeholder (e.g., box
    // drawing vertical bars) keep their column positions.
    static func substituteFixedWidthPlaceholders(_ template: String, replacements: [String: String]) -> String {
        // For determinism iterate over lines and perform replacement per occurrence
        let lines = template.components(separatedBy: "\n")
        var newLines: [String] = []
        for var line in lines {
            for (token, value) in replacements {
                // Replace all occurrences of token in the line
                while let range = line.range(of: token) {
                    let tokenLength = token.count
                    let str = value
                    let padded: String
                    if str.count >= tokenLength {
                        padded = String(str.prefix(tokenLength))
                    } else {
                        // LEFT-ALIGN value within the placeholder width by appending spaces after it
                        let padCount = tokenLength - str.count
                        padded = str + String(repeating: " ", count: padCount)
                    }
                    line.replaceSubrange(range, with: padded)
                }
            }
            newLines.append(line)
        }
        return newLines.joined(separator: "\n")
    }
}
