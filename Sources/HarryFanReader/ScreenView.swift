//
//  ScreenView.swift
//  harryfan-reader
//
//  Created by @vt887 on 9/1/25.
//

import SwiftUI

// View for rendering the main text screen in the app
struct ScreenView: View {
    // Observed document model for the screen
    @ObservedObject var document: TextDocument
    // Font manager environment object
    @EnvironmentObject var fontManager: FontManager

    // Optional custom content to display
    var contentToDisplay: String?
    // Number of rows to display
    var displayRows: Int
    // Row offset for line numbering
    var rowOffset: Int = 0
    // Background color for the screen
    var backgroundColor: Color = Colors.theme.background
    // Font color for the screen
    var fontColor: Color = Colors.theme.foreground

    // Number of columns in the screen (from AppSettings)
    static let cols = AppSettings.cols
    // Character width in pixels (from AppSettings)
    static let charW = AppSettings.charW
    // Character height in pixels (from AppSettings)
    static let charH = AppSettings.charH

    // MS-DOS-like background color
    private let bgColor = Colors.theme.background
    // MS-DOS-like foreground color
    private let fgColor = Colors.theme.foreground

    // Main view body rendering the text screen
    var body: some View {
        Canvas { context, size in
            // Conditionally enable anti-aliasing for smoother text rendering
            if AppSettings.enableAntiAliasing {
                context.withCGContext { cgContext in
                    cgContext.setShouldAntialias(true)
                    cgContext.setShouldSmoothFonts(true)
                    cgContext.setAllowsFontSmoothing(true)
                }
            }

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
                linesToRender = Array(document.content[startLine ..< min(document.content.count, startLine + displayRows)])
            }

            // Precompute cell size to fit exactly 640x384; if canvas is larger, center the content
            let idealSize = CGSize(width: CGFloat(ScreenView.cols * ScreenView.charW), height: CGFloat(displayRows * ScreenView.charH))
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

    // Draws a single character at the given position
    private func drawChar(_ character: Character,
                          at pos: (Int, Int),
                          in context: GraphicsContext,
                          origin: CGPoint,
                          customFgColor: Color? = nil)
    {
        guard let bitmap = fontManager.getCharacterBitmap(for: character),
              bitmap.count == (ScreenView.charW * ScreenView.charH) else { return }

        let (column, row) = pos
        let baseX = origin.x + CGFloat(column * ScreenView.charW)
        let baseY = origin.y + CGFloat(row * ScreenView.charH)

        // Determine foreground color to use
        let currentFgColor = customFgColor ?? fontColor

        // Draw as per-pixel rectangles with anti-aliasing
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
