//
//  MSDOSMessages.swift
//  harryfan-reader
//
//  Created by Vad Tymoshyk on 9/1/25.
//

import Foundation

struct MSDOSMessages {
    public static let welcomeMessage = """
╔══════════════════════════════════════════════════╗
║                                                  ║
║                HarryFan Reader 1.0               ║
║           Retro MS-DOS Style Text Viewer         ║
║      https://github.com/vt887/harryfan-reader    ║
║           Licensed under GPL-3.0, 2025           ║
║                                                  ║
╚══════════════════════════════════════════════════╝
"""

    public static let helloMessage = """
╔═════════════════════════════════════════════════════════════════════════════╗
║                                                                             ║    
║  Welcome! This reader is designed to give you a retro text viewing          ║
║  experience, reminiscent of the old MS-DOS days.                            ║
║                                                                             ║
║  To get started, press '3' or click '3Open' in the menu bar to open a text  ║
║  file. You can navigate through the file using the scroll buttons, or       ║
║  by pressing 'PgUp'/'PgDn' (not yet implemented in UI, but keyboard works). ║
║                                                                             ║
║  Here are some available commands:                                          ║
║  F1  - Help        (Not yet implemented)                                    ║
║  F2  - Word Wrap   (Toggle word wrapping on/off)                            ║
║  F3  - Open File   (Open a new text file)                                   ║
║  F4  - Search      (Find text within the current file)                      ║
║  F5  - Go To       (Jump to a specific line number)                         ║
║  F6  - Bookmarks   (Manage your saved bookmarks)                            ║
║  F7  - Go Start    (Jump to the beginning of the file)                      ║
║  F8  - Go End      (Jump to the end of the file)                            ║
║  F9  - Settings    (Adjust font size, empty line removal, etc.)             ║
║  F10 - Quit        (Exit the application)                                   ║
║                                                                             ║
║  Enjoy your reading experience!                                             ║
╚═════════════════════════════════════════════════════════════════════════════╝
"""

    public static let quitMessage = """
╔══════════════════════════════════════════════════╗
║                                                  ║
║         Thank you for using HarryFan Reader!     ║
║            Exiting application - Y/N?            ║
║                                                  ║
╚══════════════════════════════════════════════════╝
"""
}
