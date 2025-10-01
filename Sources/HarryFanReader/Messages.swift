//
//  Messages.swift
//  harryfan-reader
//
//  Created by @vt887 on 9/1/25.
//

import Foundation

// Enum for static app messages
enum Messages {
    static let welcomeMessage = """
    ╔══════════════════════════════════════════════════╗
    ║                                                  ║
    ║                 HarryFan Reader                  ║
    ║                                                  ║
    ║          Retro MS-DOS Style Text Viewer          ║
    ║                                                  ║
    ╚══════════════════════════════════════════════════╝
    """

    static let helpMessage = """
    ╔═════════════════════════════════════════════════════════════════════════════╗
    ║                                                                             ║
    ║  Welcome! This reader is designed to give you a retro text viewing          ║
    ║  experience, reminiscent of the old MS-DOS days.                            ║
    ║                                                                             ║
    ║  To get started, press '3' or click 'Open' in the menu bar to open a text   ║
    ║  file. You can navigate through the file using the scroll buttons, or       ║
    ║  by pressing 'PgUp'/'PgDn' (not yet implemented in UI, but keyboard works). ║
    ║                                                                             ║
    ║  Here are some available commands:                                          ║
    ║  F1  - Help        Not yet implemented                                      ║
    ║  F2  - Word Wrap   Toggle word wrapping on/off                              ║
    ║  F3  - Open File   Open a new text file                                     ║
    ║  F4  - Search      Find text within the current file                        ║
    ║  F5  - Go To       Jump to a specific line number                           ║
    ║  F6  - Bookmarks   Manage your saved bookmarks                              ║
    ║  F7  - Go Start    Jump to the beginning of the file                        ║
    ║  F8  - Go End      Jump to the end of the file                              ║
    ║  F9  - Settings    Adjust font size, empty line removal, etc.               ║
    ║  F10 - Quit        Exit the application                                     ║
    ║                                                                             ║
    ║  Enjoy your reading experience!                                             ║
    ╚═════════════════════════════════════════════════════════════════════════════╝
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

    // Returns the welcome message centered horizontally and vertically for the current screen size, with version
    static func centeredWelcomeMessage(screenWidth: Int, screenHeight: Int) -> String {
        // Debug log for ReleaseInfo.version
        DebugLogger.log("ReleaseInfo.version: '\(ReleaseInfo.version)'")
        // Replace %version% with the actual version from ReleaseInfo
        let versionedMessage = welcomeMessage.replacingOccurrences(of: "%version%", with: ReleaseInfo.version)
        let lines = versionedMessage.components(separatedBy: "\n")
        let centeredLines = lines.map { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let padding = max(0, (screenWidth - trimmed.count) / 2)
            let padStr = String(repeating: " ", count: padding)
            return padStr + trimmed
        }
        let totalLines = centeredLines.count
        let verticalPadding = max(0, (screenHeight - totalLines) / 2)
        let emptyLine = String(repeating: " ", count: screenWidth)
        let topPadding = Array(repeating: emptyLine, count: verticalPadding)
        let bottomPadding = Array(repeating: emptyLine, count: screenHeight - totalLines - verticalPadding)
        return (topPadding + centeredLines + bottomPadding).joined(separator: "\n")
    }
}
