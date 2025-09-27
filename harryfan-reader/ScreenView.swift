//
//  ScreenView.swift
//  harryfan-reader
//
//  Created by Vad Tymoshyk on 9/1/25.
//

import SwiftUI

struct ScreenView: View {
    @ObservedObject var document: TextDocument
    @EnvironmentObject var fontManager: FontManager

    var contentToDisplay: String? // New optional parameter
    var displayRows: Int // New parameter for number of rows to display
    var rowOffset: Int = 0 // New parameter for line number offset
    var backgroundColor: Color = Colors.foregroundColor // New parameter
    var fontColor: Color = Colors.textColor // New parameter

    // 80x24 text mode with 8x16 font
    static let cols = 80
    static let charW = 8
    static let charH = 16
    static let totalScreenRows = 24 // Total rows on the physical screen

    // Colors: MS-DOS like
    private let bgColor = Colors.foregroundColor
    private let fgColor = Colors.textColor

    var body: some View {
        Canvas { context, size in
            // Fill background
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(backgroundColor))

            let linesToRender: [String]
            if let customContent = contentToDisplay {
                linesToRender = customContent.components(separatedBy: "\n")
            } else {
                guard document.totalLines > 0 else { return }
                // Compute visible window so that document.currentLine is centered
                let half = displayRows / 2
                let maxStart = max(0, document.totalLines - displayRows)
                let startLine = max(0, min(maxStart, document.currentLine - half))
                linesToRender = Array(document.content[startLine ..< min(document.content.count,
                                                                         startLine + displayRows)])
            }

            // Precompute cell size to fit exactly 640x384; if canvas is larger, center the content
            let idealSize = CGSize(width: CGFloat(ScreenView.cols * ScreenView.charW),
                                   height: CGFloat(displayRows * ScreenView.charH))
            let offsetX = (size.width - idealSize.width) / 2.0

            // Draw characters
            for row in 0 ..< displayRows {
                // Draw line number
                let lineNumber = String(format: "%2d", row + rowOffset + 1)
                var currentColumn = 0
                for character in lineNumber {
                    drawChar(character,
                             at: (currentColumn, row),
                             in: context, origin: CGPoint(x: offsetX, y: 0),
                             customFgColor: Colors.scrollLaneColor)
                    currentColumn += 1
                }

                if row < linesToRender.count {
                    let line = linesToRender[row]
                    // Loop columns up to 80

                    for character in line {
                        if currentColumn >= ScreenView.cols { break }
                        drawChar(character, at: (currentColumn, row), in: context, origin: CGPoint(x: offsetX, y: 0))
                        currentColumn += 1
                    }
                    // Fill the rest with spaces
                    while currentColumn < ScreenView.cols {
                        drawChar(" ", at: (currentColumn, row), in: context, origin: CGPoint(x: offsetX, y: 0))
                        currentColumn += 1
                    }
                } else {
                    // Empty line - fill the rest with spaces
                    while currentColumn < ScreenView.cols {
                        drawChar(" ", at: (currentColumn, row), in: context, origin: CGPoint(x: offsetX, y: 0))
                        currentColumn += 1
                    }
                }
            }
        }
        .accessibilityHidden(true) // no cursor or focus ring
    }

    private func drawChar(_ character: Character,
                          at pos: (Int, Int),
                          in context: GraphicsContext,
                          origin: CGPoint,
                          customFgColor: Color? = nil) {
        guard let bitmap = fontManager.getCharacterBitmap(for: character),
              bitmap.count == (ScreenView.charW * ScreenView.charH) else { return }

        let (column, row) = pos
        let baseX = origin.x + CGFloat(column * ScreenView.charW)
        let baseY = origin.y + CGFloat(row * ScreenView.charH)

        // Determine foreground color to use
        let currentFgColor = customFgColor ?? fontColor

        // Draw as per-pixel rectangles without antialiasing
        for rowIndex in 0 ..< ScreenView.charH {
            for columnIndex in 0 ..< ScreenView.charW {
                if bitmap[rowIndex * ScreenView.charW + columnIndex] {
                    let rect = CGRect(x: baseX + CGFloat(columnIndex),
                                      y: baseY + CGFloat(rowIndex),
                                      width: 1,
                                      height: 1)
                    context.fill(Path(rect), with: .color(currentFgColor))
                }
            }
        }
    }
}
