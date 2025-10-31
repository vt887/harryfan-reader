//
//  ScreenView.swift
//  harryfan-reader
//
//  Created by @vt887 on 9/1/25.
//

import AppKit
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
    // Buttons discovered in this layer (for overlay interactive regions)
    var buttons: [OverlayButton] = []
    // Optional overlay kind recorded by OverlayFactory
    var overlayKind: OverlayKind?

    init(rows: Int = Settings.rows, cols: Int = Settings.cols) {
        grid = []
        for _ in 0 ..< rows {
            var rowArray: [ScreenCell] = []
            for _ in 0 ..< cols {
                rowArray.append(ScreenCell(char: " ", fgColor: nil, bgColor: nil))
            }
            grid.append(rowArray)
        }
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

    // Optional tap handler that receives (col, row, isSecondary)
    // isSecondary == true means the click was a secondary (right) mouse click
    var tapHandler: ((Int, Int, Bool) -> Void)?

    // Number of columns in the screen (from Settings)
    static let cols = Settings.cols
    // Character width in pixels (from Settings)
    static let charW = Settings.charW
    // Character height in pixels (from Settings)
    static let charH = Settings.charH

    // Only overlay layers are stored in @State, now passed as a Binding
    @Binding var overlayLayers: [ScreenLayer]
    @Binding var overlayOpacities: [UUID: Double]

    // Helper function to create inverted screen cell
    private func createInvertedCell(_ char: Character) -> ScreenCell {
        ScreenCell(char: char,
                   fgColor: Colors.theme.titleBarBackground,
                   bgColor: Colors.theme.menuBarForeground)
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
    private func handleActionBarDigitInversion(_ base: inout ScreenLayer, row: Int, lineChars: [Character], col: inout Int) -> Bool {
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
        let isActionBarRow = displayRows == 1 && rowOffset == document.rows - 1

        for (row, line) in lines.prefix(displayRows).enumerated() {
            var col = 0
            let lineChars = Array(line)
            while col < min(lineChars.count, ScreenView.cols) {
                let char = lineChars[col]
                if isActionBarRow {
                    // Handle menu bar digit inversion (1-10 and their leading spaces)
                    if handleActionBarDigitInversion(&base, row: row, lineChars: lineChars, col: &col) {
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
                    // Previously we only copied overlay cells that had a non-space character.
                    // That prevented overlay backgrounds (which are often stored on space chars)
                    // from being applied. Copy the cell if it either has a non-space char or
                    // an explicit background color. Also apply the overlay alpha to both
                    // foreground and background colors.
                    if cell.char != Character(" ") || cell.bgColor != nil {
                        var adjusted = cell
                        if let c = cell.fgColor {
                            adjusted.fgColor = c.opacity(alpha)
                        }
                        if let bg = cell.bgColor {
                            adjusted.bgColor = bg.opacity(alpha)
                        }
                        result[row][col] = adjusted
                    }
                }
            }
        }
        return result
    }

    // Main view body rendering the text screen (fixed-size canvas, scaled by Settings)
    var body: some View {
        let idealSize = Settings.contentSize(rows: displayRows, cols: ScreenView.cols)
        let charPx = Settings.pixelCharSize()
        return Canvas { context, size in
            // Configure antialiasing according to Settings
            context.withCGContext { cg in
                if Settings.enableAntiAliasing {
                    cg.setAllowsAntialiasing(true)
                    cg.setShouldAntialias(true)
                    cg.interpolationQuality = .high
                    cg.setBlendMode(.normal)
                } else {
                    cg.setAllowsAntialiasing(false)
                    cg.setShouldAntialias(false)
                    cg.interpolationQuality = .none
                    cg.setBlendMode(.copy)
                }
            }

            // Fill background
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(backgroundColor))

            let grid = compositeGrid()

            for row in 0 ..< displayRows {
                for col in 0 ..< ScreenView.cols {
                    let cell = grid[row][col]
                    drawChar(cell.char, at: (col, row), in: context, origin: CGPoint(x: 0, y: 0), customFgColor: cell.fgColor, customBgColor: cell.bgColor)
                }
            }
        }
        .frame(width: idealSize.width, height: idealSize.height)
        .gesture(DragGesture(minimumDistance: 0)
            .onEnded { value in
                let loc = value.location
                guard loc.x >= 0, loc.x <= idealSize.width, loc.y >= 0, loc.y <= idealSize.height else { return }
                let col = Int(loc.x / charPx.width)
                let row = Int(loc.y / charPx.height)
                tapHandler?(col, row, false)
            })
        .overlay(
            MouseEventCatcher { localPoint, isSecondary in
                guard localPoint.x >= 0, localPoint.x <= idealSize.width, localPoint.y >= 0, localPoint.y <= idealSize.height else { return }
                let col = Int(localPoint.x / charPx.width)
                let row = Int(localPoint.y / charPx.height)
                tapHandler?(col, row, isSecondary)
            }
            .frame(width: idealSize.width, height: idealSize.height)
        )
        .accessibilityHidden(true)
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
        let scale = Settings.scaleFactor
        let scaledCharW = CGFloat(ScreenView.charW) * scale
        let scaledCharH = CGFloat(ScreenView.charH) * scale
        // Compute character bounds snapped to integral coordinates to ensure no seams
        let rawLeft = origin.x + CGFloat(column) * scaledCharW
        let rawTop  = origin.y + CGFloat(row) * scaledCharH
        let charLeft = (rawLeft).rounded(.toNearestOrAwayFromZero)
        let charTop  = (rawTop).rounded(.toNearestOrAwayFromZero)
        let charRight = (rawLeft + scaledCharW).rounded(.toNearestOrAwayFromZero)
        let charBottom = (rawTop + scaledCharH).rounded(.toNearestOrAwayFromZero)
        let baseX = charLeft
        let baseY = charTop
        let charWInt = max(0, Int((charRight - charLeft).rounded(.towardZero)))
        let charHInt = max(0, Int((charBottom - charTop).rounded(.towardZero)))

        let currentFgColor = customFgColor ?? fontColor

        // Draw background if present
        if let bg = customBgColor {
            let rect = CGRect(x: baseX, y: baseY, width: CGFloat(charWInt), height: CGFloat(charHInt))
             if rect.width > 0 && rect.height > 0 {
                 context.fill(Path(rect), with: .color(bg))
             }
        }

        // Draw character pixels scaled by scaleFactor based on bitmap
        for yIndex in 0 ..< ScreenView.charH {
            for xIndex in 0 ..< ScreenView.charW {
                if bitmap[yIndex * ScreenView.charW + xIndex] {
                    // Boundaries derived from integer character bounds (no seams between cells)
                    let x0 = baseX + CGFloat(Int((CGFloat(xIndex) * CGFloat(charWInt) / CGFloat(ScreenView.charW)).rounded(.towardZero)))
                    let x1 = baseX + CGFloat(Int((CGFloat(xIndex + 1) * CGFloat(charWInt) / CGFloat(ScreenView.charW)).rounded(.towardZero)))
                    let y0 = baseY + CGFloat(Int((CGFloat(yIndex) * CGFloat(charHInt) / CGFloat(ScreenView.charH)).rounded(.towardZero)))
                    let y1 = baseY + CGFloat(Int((CGFloat(yIndex + 1) * CGFloat(charHInt) / CGFloat(ScreenView.charH)).rounded(.towardZero)))
                    let rectW = max(0, x1 - x0)
                    let rectH = max(0, y1 - y0)
                    if rectW > 0 && rectH > 0 {
                        let pixelRect = CGRect(x: x0, y: y0, width: rectW, height: rectH)
                        context.fill(Path(pixelRect), with: .color(currentFgColor))
                    }
                }
            }
        }
    }
}

// NSViewRepresentable used to catch mouseDown and rightMouseDown on macOS
private struct MouseEventCatcher: NSViewRepresentable {
    // localPoint is in the view's coordinate space (origin at top-left of the catcher view)
    var handler: (CGPoint, Bool) -> Void

    func makeNSView(context _: Context) -> MouseCatcherView {
        let v = MouseCatcherView()
        v.handler = handler
        v.wantsLayer = true
        // Ensure the view accepts mouse events
        v.addTrackingArea(NSTrackingArea(rect: v.bounds, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect, .mouseMoved], owner: v, userInfo: nil))
        return v
    }

    func updateNSView(_ nsView: MouseCatcherView, context _: Context) {
        // no-op; handler may be updated by re-creating the representable
        nsView.handler = handler
    }

    class MouseCatcherView: NSView {
        var handler: ((CGPoint, Bool) -> Void)?

        override func mouseDown(with event: NSEvent) {
            let local = convert(event.locationInWindow, from: nil)
            handler?(local, false)
        }

        override func rightMouseDown(with event: NSEvent) {
            let local = convert(event.locationInWindow, from: nil)
            handler?(local, true)
        }

        // Support two-button mice calling otherMouseDown as secondary as well
        override func otherMouseDown(with event: NSEvent) {
            let local = convert(event.locationInWindow, from: nil)
            handler?(local, true)
        }

        override var acceptsFirstResponder: Bool { true }
    }
}
