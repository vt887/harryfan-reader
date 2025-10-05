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
                count: cols,
            ),
            count: rows,
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
    @Binding var overlayOpacities: [UUID: Double]

    // Helper function to create inverted screen cell
    private func createInvertedCell(_ char: Character) -> ScreenCell {
        ScreenCell(
            char: char,
            fgColor: Colors.theme.titleBarBackground,
            bgColor: Colors.theme.menuBarForeground,
        )
    }

    // Helper function to detect and handle digit patterns
    private func detectDigitPattern(_ lineChars: [Character], _ col: Int) -> (pattern: String, length: Int)? {
        let char = lineChars[col]

        // Check for "10" first (two-digit number)
        if char == "1", col + 1 < lineChars.count, lineChars[col + 1] == "0" {
            return ("10", 2)
        }

        // Check for single digits 1-9
        if char.isNumber,
           let digit = char.wholeNumberValue, (1 ... 9).contains(digit)
        {
            return (String(digit), 1)
        }

        return nil
    }

    // Helper function to handle menu bar digit inversion
    private func handleMenuBarDigitInversion(_ base: inout ScreenLayer, row: Int, lineChars: [Character], col: inout Int) -> Bool {
        // Check if we have a leading space and a valid digit pattern
        guard col > 0, lineChars[col - 1] == " ",
              let (pattern, length) = detectDigitPattern(lineChars, col)
        else {
            return false
        }

        // Invert leading space
        base[row, col - 1] = createInvertedCell(" ")

        // Invert the digit pattern
        for i in 0 ..< length {
            let index = pattern.index(pattern.startIndex, offsetBy: i)
            base[row, col + i] = createInvertedCell(pattern[index])
        }

        col += length
        return true
    }

    private func makeBaseLayer() -> ScreenLayer {
        var base = ScreenLayer(rows: displayRows, cols: ScreenView.cols)
        // Get lines to display, either from overlay content or document
        let lines: [String] = contentToDisplay?.components(separatedBy: .newlines) ?? document.getVisibleLines(displayRows: displayRows)

        // Helper: is this the menu bar row?
        let isMenuBarRow = displayRows == 1 && rowOffset == document.rows - 1

        for (row, line) in lines.prefix(displayRows).enumerated() {
            var col = 0
            let lineChars = Array(line)
            while col < min(lineChars.count, ScreenView.cols) {
                let char = lineChars[col]
                if isMenuBarRow {
                    // Handle menu bar digit inversion (1-10 and their leading spaces)
                    if handleMenuBarDigitInversion(&base, row: row, lineChars: lineChars, col: &col) {
                        continue
                    }
                    // Menu bar: normal menu item text
                    base[row, col] = ScreenCell(char: char, fgColor: Colors.theme.menuBarForeground, bgColor: Colors.theme.menuBarBackground)
                } else {
                    // Normal content
                    base[row, col] = ScreenCell(char: char, fgColor: fontColor, bgColor: nil)
                }
                col += 1
            }
        }
        return base
    }

    // Composite the base layer with overlays
    func compositeGrid() -> [[ScreenCell]] {
        let gridRows = displayRows
        let gridCols = ScreenView.cols
        var result = makeBaseLayer().grid
        for layer in overlayLayers {
            let alpha = overlayOpacities[layer.id] ?? 1.0
            for row in 0 ..< min(gridRows, layer.grid.count) {
                for col in 0 ..< min(gridCols, layer.grid[row].count) {
                    let cell = layer.grid[row][col]
                    if cell.char != " " {
                        var adjusted = cell
                        if let c = cell.fgColor {
                            adjusted.fgColor = c.opacity(alpha)
                        }
                        result[row][col] = adjusted
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
                    drawChar(cell.char, at: (col, row), in: context, origin: CGPoint(x: offsetX, y: 0), customFgColor: cell.fgColor, customBgColor: cell.bgColor)
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
                          customFgColor: Color? = nil,
                          customBgColor: Color? = nil)
    {
        guard let bitmap = fontManager.getCharacterBitmap(for: character),
              bitmap.count == (ScreenView.charW * ScreenView.charH) else { return }

        let (column, row) = pos
        let baseX = origin.x + CGFloat(column * ScreenView.charW)
        let baseY = origin.y + CGFloat(row * ScreenView.charH)

        // Determine foreground and background color to use
        let currentFgColor = customFgColor ?? fontColor
        let currentBgColor = customBgColor

        // Draw background color if present
        if let bg = currentBgColor {
            let rect = CGRect(x: baseX, y: baseY, width: CGFloat(ScreenView.charW), height: CGFloat(ScreenView.charH))
            context.fill(Path(rect), with: .color(bg))
        }

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
                                height: 1.0,
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
                            height: 1,
                        )
                        context.fill(Path(rect), with: .color(currentFgColor))
                    }
                }
            }
        }
    }
}
