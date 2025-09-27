//
//  MSDOSScreenView.swift
//  harryfan-reader
//
//  Created by Vad Tymoshyk on 9/1/25.
//

import SwiftUI

struct MSDOSScreenView: View {
    @ObservedObject var document: TextDocument
    @EnvironmentObject var fontManager: FontManager
    
    var contentToDisplay: String? = nil // New optional parameter

    // 80x24 text mode with 8x16 font
    private let cols = 80
    private let rows = 24
    private let charW = 8
    private let charH = 16

    // Colors: MS-DOS like
    private let bgColor = MSDOSColors.foregroundColor
    private let fgColor = MSDOSColors.textColor

    var body: some View {
        Canvas { context, size in
            // Fill background
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(bgColor))

            let linesToRender: [String]
            if let customContent = contentToDisplay {
                linesToRender = customContent.components(separatedBy: "\n")
            } else {
                guard document.totalLines > 0 else { return }
                // Compute visible window so that document.currentLine is centered
                let half = rows / 2
                let maxStart = max(0, document.totalLines - rows)
                let startLine = max(0, min(maxStart, document.currentLine - half))
                linesToRender = Array(document.content[startLine..<min(document.content.count, startLine + rows)])
            }
            
            // Precompute cell size to fit exactly 640x384; if canvas is larger, center the content
            let idealSize = CGSize(width: CGFloat(cols * charW), height: CGFloat(rows * charH))
            let offsetX = (size.width - idealSize.width) / 2.0
            let offsetY = (size.height - idealSize.height) / 2.0

            // Draw characters
            for row in 0..<rows {
                // Draw line number
                let lineNumber = String(format: "%2d", row + 1)
                var currentColumn = 0
                for ch in lineNumber {
                    drawChar(ch, at: (currentColumn, row), in: context, origin: CGPoint(x: offsetX, y: offsetY), customFgColor: MSDOSColors.leftScrollLane)
                    currentColumn += 1
                }
                // Draw a space after the line number
                drawChar(" ", at: (currentColumn, row), in: context, origin: CGPoint(x: offsetX, y: offsetY), customFgColor: MSDOSColors.leftScrollLane)
                currentColumn += 1 // Increment column for the space

                if row < linesToRender.count {
                    let line = linesToRender[row]
                    // Loop columns up to 80
                    
                    for ch in line {
                        if currentColumn >= cols { break }
                        drawChar(ch, at: (currentColumn, row), in: context, origin: CGPoint(x: offsetX, y: offsetY))
                        currentColumn += 1
                    }
                    // Fill the rest with spaces
                    while currentColumn < cols {
                        drawChar(" ", at: (currentColumn, row), in: context, origin: CGPoint(x: offsetX, y: offsetY))
                        currentColumn += 1
                    }
                } else {
                    // Empty line - fill the rest with spaces
                    while currentColumn < cols {
                        drawChar(" ", at: (currentColumn, row), in: context, origin: CGPoint(x: offsetX, y: offsetY))
                        currentColumn += 1
                    }
                }
            }
        }
        .frame(minWidth: CGFloat(cols * charW), minHeight: CGFloat(rows * charH))
        .accessibilityHidden(true) // no cursor or focus ring
    }

    private func drawChar(_ c: Character, at pos: (Int, Int), in context: GraphicsContext, origin: CGPoint, customFgColor: Color? = nil) {
        guard let bitmap = fontManager.getCharacterBitmap(for: c), bitmap.count == (charW * charH) else { return }

        let (col, row) = pos
        let baseX = origin.x + CGFloat(col * charW)
        let baseY = origin.y + CGFloat(row * charH)

        // Determine foreground color to use
        let currentFgColor = customFgColor ?? fgColor

        // Draw as per-pixel rectangles without antialiasing
        for y in 0..<charH {
            for x in 0..<charW {
                if bitmap[y * charW + x] {
                    let rect = CGRect(x: baseX + CGFloat(x), y: baseY + CGFloat(y), width: 1, height: 1)
                    context.fill(Path(rect), with: .color(currentFgColor))
                }
            }
        }
    }
}
