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

    // Simple helper to substitute common placeholders in message templates
    private static func applyPlaceholders(_ template: String) -> String {
        var result = template
        result = result.replacingOccurrences(of: "%version%", with: ReleaseInfo.version)
        return result
    }

    // Public computed properties apply placeholders on access
    static var aboutMessage: String { applyPlaceholders(aboutTemplate) }
    static var welcomeMessage: String { applyPlaceholders(welcomeTemplate) }

    // Returns the welcome message centered horizontally and vertically for the current screen size, with version
    static func centeredWelcomeMessage(screenWidth: Int, screenHeight: Int) -> String {
        DebugLogger.log("ReleaseInfo.version: '\(ReleaseInfo.version)'")
        // Use the template with placeholders applied to ensure %version% is replaced
        let versionedMessage = applyPlaceholders(welcomeTemplate)
        let lines = versionedMessage.components(separatedBy: "\n")
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
}
