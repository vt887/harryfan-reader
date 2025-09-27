//
//  TextDocument.swift
//  harryfan-reader
//
//  Created by Vad Tymoshyk on 9/1/25.
//

import SwiftUI
import Foundation

class TextDocument: ObservableObject {
    @Published var content: [String] = []
    @Published var currentLine: Int = 0
    @Published var totalLines: Int = 0
    @Published var encoding: String = "Unknown"
    @Published var fileName: String = ""
    @Published var removeEmptyLines: Bool = true
    @Published var wordWrap: Bool = true
    @Published var wrapWidth: Int = 80
    @Published var shouldShowQuitMessage: Bool = false
    
    private var originalData: Data?
    
    public var quitMessage: String { MSDOSMessages.quitMessage }
    
    func loadWelcomeText() {
        content = splitLines(MSDOSMessages.welcomeMessage)
        totalLines = content.count
        currentLine = 0
        fileName = ""
        encoding = "ASCII"
    }
    
    func openFile(at url: URL) {
        do {
            fileName = url.lastPathComponent
            originalData = try Data(contentsOf: url)
            guard let data = originalData else { return }
            
            let decodedString = decodeCP866(from: data)
            let rawLines = cleanLines(splitLines(decodedString))
            content = wrapLines(rawLines)
            encoding = "CP866"
            print("File loaded with CP866 encoding")
            totalLines = content.count
            currentLine = 0
        } catch {
            print("Error opening file: \(error)")
        }
    }
    
    func getTitleBarText() -> String {
        let appName = "HarryFan Reader"
        
        if fileName.isEmpty {
            return appName.padding(toLength: 80, withPad: " ", startingAt: 0)
        } else {
            let percent = totalLines > 0 ? Int((Double(currentLine + 1) / Double(totalLines)) * 100.0) : 0
            let statusText = "Line \(currentLine + 1) of \(totalLines) \(percent)% \(encoding)"
            
            let availableWidth = 80 - appName.count - statusText.count - 3 // 3 for " - " delimiters
            
            var displayFileName = fileName
            if fileName.count > availableWidth {
                displayFileName = String(fileName.prefix(availableWidth - 3)) + "..."
            }
            
            let title = "\(appName) - \(displayFileName)"
            let rightPaddedTitle = title.padding(toLength: 80 - statusText.count, withPad: " ", startingAt: 0)
            return "\(rightPaddedTitle)\(statusText)"
        }
    }
    
    func getMenuBarText() -> String {
        let menuItems = [
            "1Help", "2Wrap", "3Open", "4Search", "5Goto",
            "6Bookm", "7Start", "8End", "9Menu", "10Quit"
        ]
        let menuBarString = menuItems.map { $0.padding(toLength: 7, withPad: " ", startingAt: 0) }.joined(separator: "")
        return menuBarString.padding(toLength: 80, withPad: " ", startingAt: 0)
    }
    
    private func decodeCP866(from data: Data) -> String {
        // Повна таблиця CP866 (0x00–0xFF)
        let unicodePoints: [UInt32] = [
            0x0000,0x0001,0x0002,0x0003,0x0004,0x0005,0x0006,0x0007,
            0x0008,0x0009,0x000A,0x000B,0x000C,0x000D,0x000E,0x000F,
            0x0010,0x0011,0x0012,0x0013,0x0014,0x0015,0x0016,0x0017,
            0x0018,0x0019,0x001A,0x001B,0x001C,0x001D,0x001E,0x001F,
            0x0020,0x0021,0x0022,0x0023,0x0024,0x0025,0x0026,0x0027,
            0x0028,0x0029,0x002A,0x002B,0x002C,0x002D,0x002E,0x002F,
            0x0030,0x0031,0x0032,0x0033,0x0034,0x0035,0x0036,0x0037,
            0x0038,0x0039,0x003A,0x003B,0x003C,0x003D,0x003E,0x003F,
            0x0040,0x0041,0x0042,0x0043,0x0044,0x0045,0x0046,0x0047,
            0x0048,0x0049,0x004A,0x004B,0x004C,0x004D,0x004E,0x004F,
            0x0050,0x0051,0x0052,0x0053,0x0054,0x0055,0x0056,0x0057,
            0x0058,0x0059,0x005A,0x005B,0x005C,0x005D,0x005E,0x005F,
            0x0060,0x0061,0x0062,0x0063,0x0064,0x0065,0x0066,0x0067,
            0x0068,0x0069,0x006A,0x006B,0x006C,0x006D,0x006E,0x006F,
            0x0070,0x0071,0x0072,0x0073,0x0074,0x0075,0x0076,0x0077,
            0x0078,0x0079,0x007A,0x007B,0x007C,0x007D,0x007E,0x007F,
            0x0410,0x0411,0x0412,0x0413,0x0414,0x0415,0x0416,0x0417,
            0x0418,0x0419,0x041A,0x041B,0x041C,0x041D,0x041E,0x041F,
            0x0420,0x0421,0x0422,0x0423,0x0424,0x0425,0x0426,0x0427,
            0x0428,0x0429,0x042A,0x042B,0x042C,0x042D,0x042E,0x042F,
            0x0430,0x0431,0x0432,0x0433,0x0434,0x0435,0x0436,0x0437,
            0x0438,0x0439,0x043A,0x043B,0x043C,0x043D,0x043E,0x043F,
            0x2591,0x2592,0x2593,0x2502,0x2524,0x2561,0x2562,0x2556,
            0x2555,0x2563,0x2551,0x2557,0x255D,0x255C,0x255B,0x2510,
            0x2514,0x2534,0x252C,0x251C,0x2500,0x253C,0x255E,0x255F,
            0x255A,0x2554,0x2569,0x2566,0x2560,0x2550,0x256C,0x2567,
            0x2568,0x2564,0x2565,0x2559,0x2558,0x2552,0x2553,0x256B,
            0x256A,0x2518,0x250C,0x2588,0x2584,0x258C,0x2590,0x2580,
            0x0440,0x0441,0x0442,0x0443,0x0444,0x0445,0x0446,0x0447,
            0x0448,0x0449,0x044A,0x044B,0x044C,0x044D,0x044E,0x044F,
            0x0401,0x0451,0x0404,0x0454,0x0407,0x0457,0x040E,0x045E,
            0x00B0,0x2219,0x00B7,0x221A,0x2116,0x00A4,0x25A0,0x00A0
        ]

        var result = String.UnicodeScalarView()
        for byte in data {
            let scalar = UnicodeScalar(unicodePoints[Int(byte)])!
            result.append(scalar)
        }
        return String(result)
    }

    
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
    
    private func splitLines(_ text: String) -> [String] {
        // Handle different line ending formats properly
        // Replace \r\n with \n first, then split by \n
        let normalizedText = text.replacingOccurrences(of: "\r\n", with: "\n")
        return normalizedText.components(separatedBy: "\n")
    }
    
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
    
    func closeFile() {
        content = []
        currentLine = 0
        totalLines = 0
        encoding = "Unknown"
        fileName = ""
        originalData = nil
    }
    
    func reloadWithNewSettings() {
        guard let data = originalData else { return }

        let decodedString = decodeCP866(from: data)
        let rawLines = cleanLines(splitLines(decodedString))
        content = wrapLines(rawLines)
        totalLines = content.count
    }
    
    // Navigation methods
    func gotoLine(_ line: Int) {
        let targetLine = max(0, min(line - 1, totalLines - 1))
        currentLine = targetLine
    }
    
    func gotoStart() {
        currentLine = 0
    }
    
    func gotoEnd() {
        currentLine = max(0, totalLines - 1)
    }
    
    func pageUp() {
        let pageSize = 20 // Number of lines per page
        currentLine = max(0, currentLine - pageSize)
    }
    
    func pageDown() {
        let pageSize = 20 // Number of lines per page
        currentLine = min(totalLines - 1, currentLine + pageSize)
    }
    
    // Search functionality
    func search(_ query: String, direction: SearchDirection = .forward, caseSensitive: Bool = false) -> Int? {
        guard !query.isEmpty else { return nil }
        
        let searchQuery = caseSensitive ? query : query.lowercased()
        let lines = caseSensitive ? content : content.map { $0.lowercased() }
        
        if direction == .forward {
            // Search from current line + 1 to end
            for i in (currentLine + 1)..<lines.count {
                if lines[i].contains(searchQuery) {
                    return i
                }
            }
            // Wrap around to beginning
            for i in 0...currentLine {
                if lines[i].contains(searchQuery) {
                    return i
                }
            }
        } else {
            // Search from current line - 1 to beginning
            for i in stride(from: currentLine - 1, through: 0, by: -1) {
                if lines[i].contains(searchQuery) {
                    return i
                }
            }
            // Wrap around to end
            for i in stride(from: lines.count - 1, through: currentLine, by: -1) {
                if lines[i].contains(searchQuery) {
                    return i
                }
            }
        }
        
        return nil
    }
    
    // Get current line content
    func getCurrentLine() -> String {
        guard currentLine >= 0 && currentLine < content.count else {
            return ""
        }
        return content[currentLine]
    }
    
    // Get visible lines for display
    func getVisibleLines() -> [String] {
        let startLine = max(0, currentLine)
        let endLine = min(content.count, startLine + 24) // Show 24 lines as default
        return Array(content[startLine..<endLine])
    }
}

enum SearchDirection {
    case forward
    case backward
}
