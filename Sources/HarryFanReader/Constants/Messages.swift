//
//  Messages.swift
//  harryfan-reader
//
//  Created by @vt887 on 9/1/25.
//

import Foundation

// Enum for static app messages
enum Messages {
    static let aboutMessage = """
    ╔═══════════════════════════════════════════╗
    ║              HarryFan Reader              ║
    ║                                           ║
    ║          Version xxxxxxxxxxxx             ║
    ║                                           ║
    ║             Press any key...              ║
    ╚═══════════════════════════════════════════╝
    """

    static let welcomeMessage = """
    ╔═══════════════════════════════════════════╗
    ║              HarryFan Reader              ║
    ║                                           ║
    ║      Retro MS-DOS Style Text Viewer       ║
    ║                                           ║
    ║             Press any key...              ║
    ╚═══════════════════════════════════════════╝
    """

    static let helpMessage = """
    ╔═══════════════════════════════════════════════════════╗
    ║  F1  - Help        Show/hide this help screen         ║
    ║  F2  - Word Wrap   Toggle word wrapping on/off        ║
    ║  F3  - Open File   Open a new text file               ║
    ║  F7  - Go Start    Jump to the beginning of the file  ║
    ║  F8  - Go End      Jump to the end of the file        ║
    ║  F10 - Quit        Exit the application               ║
    ╚═══════════════════════════════════════════════════════╝
    """

    static let quitMessage = """
    ╔══════════════════════════════════════════════════╗
    ║                                                  ║
    ║        Thank you for using HarryFan Reader!      ║
    ║                                                  ║
    ║           Exiting application - Y/N?             ║
    ║                                                  ║
    ╚══════════════════════════════════════════════════╝
    """

    static let searchMessage = """
    ╔═════════════════[ Search ]═══════════════════════╗
    ║  Search for the string                           ║
    ║  xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx   ║
    ╚══════════════════════════════════════════════════╝
    """

    // Returns the welcome message centered horizontally and vertically for the current screen size, with version
    static func centeredWelcomeMessage(screenWidth: Int, screenHeight: Int) -> String {
        DebugLogger.log("ReleaseInfo.version: '\(ReleaseInfo.version)'")
        let versionedMessage = welcomeMessage.replacingOccurrences(of: "%version%", with: ReleaseInfo.version)
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
