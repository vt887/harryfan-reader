//
//  ScreenView.swift
//  harryfan-reader
//
//  Created by @vt887 on 9/1/25.
//

import SwiftUI

// Represents a single cell in the screen grid
struct ScreenCell {
    var char: Character
    var fgColor: Color?
    var bgColor: Color?
}

// Represents a layer (window) of the screen
struct ScreenLayer: Identifiable {
    let id = UUID()
    var grid: [[ScreenCell]] // [row][col], 24x80

    init(rows: Int = AppSettings.rows, cols: Int = AppSettings.cols) {
        grid = Array(
            repeating: Array(
                repeating: ScreenCell(char: " ", fgColor: nil, bgColor: nil),
                count: cols
            ),
            count: rows
        )
    }

    subscript(row: Int, col: Int) -> ScreenCell {
        get { grid[row][col] }
        set { grid[row][col] = newValue }
    }
}

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
    // New flag to highlight the cursor (current) line (top visible line)
    var highlightCursorLine: Bool = false

    // Number of columns in the screen (from AppSettings)
    static let cols = AppSettings.cols
    // Character width in pixels (from AppSettings)
    static let charW = AppSettings.charW
    // Character height in pixels (from AppSettings)
    static let charH = AppSettings.charH

    // Only overlay layers are stored in @State, now passed as a Binding
    @Binding var overlayLayers: [ScreenLayer]

    // Helper to generate the base layer from main content
    private func makeBaseLayer() -> ScreenLayer {
        var base = ScreenLayer(rows: displayRows, cols: ScreenView.cols)
        let lines: [String] = if let content = contentToDisplay {
            content.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        } else {
            document.getVisibleLines(displayRows: displayRows)
        }
        for (row, line) in lines.prefix(displayRows).enumerated() {
            for (col, char) in line.prefix(ScreenView.cols).enumerated() {
                base[row, col] = ScreenCell(char: char, fgColor: fontColor, bgColor: nil)
            }
        }
        return base
    }

    // Composite the base layer with overlays
    func compositeGrid() -> [[ScreenCell]] {
        let rows = displayRows
        let cols = ScreenView.cols
        var result = makeBaseLayer().grid
        for layer in overlayLayers {
            for row in 0 ..< min(rows, layer.grid.count) {
                for col in 0 ..< min(cols, layer.grid[row].count) {
                    let cell = layer.grid[row][col]
                    if cell.char != " " {
                        result[row][col] = cell
                    }
                }
            }
        }
        return result
    }

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

            let grid = compositeGrid()
            let idealSize = CGSize(width: CGFloat(ScreenView.cols * ScreenView.charW), height: CGFloat(displayRows * ScreenView.charH))
            let offsetX = (size.width - idealSize.width) / 2.0

            // Determine cursor line index within the visible viewport (removed highlight feature)
            // (Cursor line highlight disabled as per user request)

            for row in 0 ..< displayRows {
                for col in 0 ..< ScreenView.cols {
                    let cell = grid[row][col]
                    drawChar(cell.char, at: (col, row), in: context, origin: CGPoint(x: offsetX, y: 0), customFgColor: cell.fgColor)
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

        if AppSettings.enableAntiAliasing {
            // Draw with anti-aliasing for smoother text
            context.withCGContext { cgContext in
                cgContext.setShouldAntialias(true)
                cgContext.setAllowsAntialiasing(true)
                cgContext.setShouldSmoothFonts(true)

                for rowIndex in 0 ..< ScreenView.charH {
                    for columnIndex in 0 ..< ScreenView.charW {
                        if bitmap[rowIndex * ScreenView.charW + columnIndex] {
                            let rect = CGRect(
                                x: baseX + CGFloat(columnIndex),
                                y: baseY + CGFloat(rowIndex),
                                width: 1.0,
                                height: 1.0
                            )
                            cgContext.setFillColor(currentFgColor.cgColor ?? CGColor(red: 1, green: 1, blue: 1, alpha: 1))
                            cgContext.fill(rect)
                        }
                    }
                }
            }
        } else {
            // Draw without anti-aliasing for sharp, pixel-perfect text
            for rowIndex in 0 ..< ScreenView.charH {
                for columnIndex in 0 ..< ScreenView.charW {
                    if bitmap[rowIndex * ScreenView.charW + columnIndex] {
                        let rect = CGRect(
                            x: baseX + CGFloat(columnIndex),
                            y: baseY + CGFloat(rowIndex),
                            width: 1,
                            height: 1
                        )
                        context.fill(Path(rect), with: .color(currentFgColor))
                    }
                }
            }
        }
    }

    // Helper to create a centered overlay layer from a string
    func centeredOverlayLayer(from message: String) -> ScreenLayer {
        var layer = ScreenLayer(rows: displayRows, cols: ScreenView.cols)
        let lines = message.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        let totalLines = lines.count
        let verticalPadding = max(0, (displayRows - totalLines) / 2)
        for (i, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let padding = max(0, (ScreenView.cols - trimmed.count) / 2)
            let startCol = padding
            for (j, char) in trimmed.enumerated() {
                let row = verticalPadding + i
                let col = startCol + j
                if row < displayRows, col < ScreenView.cols {
                    layer[row, col] = ScreenCell(char: char, fgColor: fontColor, bgColor: nil)
                }
            }
        }
        return layer
    }
}
