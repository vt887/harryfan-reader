//
//  Overlays.swift
//  harryfan-reader
//
//  Created by @vt887 on 10/01/25.
//

import Foundation
import SwiftUI

// Minimal overlay action type used by OverlayButton.
// Kept intentionally simple: it stores the originating label and can be extended later.
struct OverlayAction {
    let label: String
    init(fromLabel: String) {
        label = fromLabel
    }
}

// Represents a clickable button region inside an overlay layer.
struct OverlayButton {
    let label: String
    let row: Int
    let col: Int
    let length: Int
    let action: OverlayAction
}

// OverlayKind defines the different types of overlays
// that can be displayed in the application, such as
// welcome, help, custom messages, or file text previews.
enum OverlayKind: Int, CaseIterable {
    case welcome = 0
    case help
    case quit
    case about
    case search
    case goto
    case menu
    case library
    case statistics

    // Returns the message string associated with each overlay kind.
    // Implemented via a static array indexed by the enum's rawValue to avoid
    // dictionary hashing and to make lookups predictable and allocation-free.
    var message: String {
        let idx = rawValue
        precondition(idx >= 0 && idx < Self._messages.count, "OverlayKind message index out of range")
        return Self._messages[idx]
    }

    // Internal static mapping from OverlayKind index to its message string.
    // The order here must match the enum case order above.
    private static let _messages: [String] = [
        Messages.welcomeMessage,
        Messages.helpMessage,
        Messages.quitMessage,
        Messages.aboutMessage,
        Messages.searchMessage,
        Messages.gotoMessage,
        Messages.menuMessage,
        Messages.libraryMessage,
        Messages.statisticsMessage,
    ]
}

// Map an OverlayKind to its corresponding ActiveOverlay value.
extension OverlayKind {
    var activeOverlay: ActiveOverlay {
        switch self {
        case .welcome: .welcome
        case .help: .help
        case .quit: .quit
        case .about: .about
        case .search: .search
        case .goto: .goto
        case .menu: .menu
        case .library: .library
        case .statistics: .statistics
        }
    }
}

// Centralized representation of the active overlay state used
// by the key handling and view code. This keeps overlay names
// and mappings in one place so they can't drift apart.
enum ActiveOverlay: Equatable {
    case none
    case welcome
    case help
    case quit
    case about
    case search
    case goto
    case menu
    case library
    case statistics
}

// Map an ActiveOverlay back to an optional OverlayKind (none -> nil).
extension ActiveOverlay {
    var overlayKind: OverlayKind? {
        switch self {
        case .none: nil
        case .welcome: .welcome
        case .help: .help
        case .quit: .quit
        case .about: .about
        case .search: .search
        case .goto: .goto
        case .menu: .menu
        case .library: .library
        case .statistics: .statistics
        }
    }
}

// CenteredOverlayLayer preserves each line exactly (no trimming) so multi-line box drawings
// remain vertically aligned and produce a straight-shaped border.
func centeredOverlayLayer(from message: String, rows: Int, cols: Int, fgColor: Color) -> ScreenLayer {
    var layer = ScreenLayer(rows: rows, cols: cols)
    let lines = message.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
    let totalLines = lines.count
    let verticalPadding = max(0, (rows - totalLines) / 2)

    // Compute bounding box using the full (not trimmed) lines so borders align
    let (startCols, endCols) = computeStartEndCols(lines: lines, cols: cols)

    let minStartCol = startCols.min() ?? 0
    let maxEndCol = endCols.max() ?? 0
    let textTopRow = verticalPadding
    let textBottomRow = verticalPadding + max(0, totalLines - 1)

    let fillTop = max(0, textTopRow - 1)
    let fillBottom = min(rows - 1, textBottomRow + 1)
    let horizontalPadding = 3
    let fillLeft = max(0, minStartCol - horizontalPadding)
    let fillRight = min(cols - 1, maxEndCol + horizontalPadding)

    if fillTop <= fillBottom, fillLeft <= fillRight {
        fillBackground(&layer, top: fillTop, bottom: fillBottom, left: fillLeft, right: fillRight, fgColor: fgColor)
    }

    for (i, line) in lines.enumerated() {
        let padding = max(0, (cols - line.count) / 2)
        let startCol = padding
        processLine(&layer, line: line, row: verticalPadding + i, startCol: startCol, fgColor: fgColor, rows: rows, cols: cols)
    }

    return layer
}

// Helper: compute start and end columns for each line
private func computeStartEndCols(lines: [String], cols: Int) -> (startCols: [Int], endCols: [Int]) {
    var startCols: [Int] = []
    var endCols: [Int] = []
    for line in lines {
        let padding = max(0, (cols - line.count) / 2)
        let startCol = padding
        let endCol = startCol + max(0, line.count - 1)
        startCols.append(startCol)
        endCols.append(endCol)
    }
    return (startCols, endCols)
}

// Helper: fill the overlay background area with spaces
private func fillBackground(_ layer: inout ScreenLayer, top: Int, bottom: Int, left: Int, right: Int, fgColor: Color) {
    for r in top ... bottom {
        for c in left ... right {
            layer[r, c] = ScreenCell(char: " ", fgColor: fgColor, bgColor: Colors.theme.overlayBackground)
        }
    }
}

// Helper: place a single character in the layer grid
private func placeChar(_ layer: inout ScreenLayer, char: Character, row: Int, col: Int, fgColor: Color, rows: Int, cols: Int) {
    if row < rows, col < cols {
        layer[row, col] = ScreenCell(char: char, fgColor: fgColor, bgColor: Colors.theme.overlayBackground)
    }
}

// Helper struct to group parameters for bracketed button placement
private struct BracketedButtonContext {
    var layer: UnsafeMutablePointer<ScreenLayer>
    let line: String
    var idx: String.Index
    var charIndex: Int
    let row: Int
    let startCol: Int
    let fgColor: Color
    let rows: Int
    let cols: Int
}

// Helper: process a bracketed button if present, else return false
private func tryProcessBracketedButton(_ ctx: inout BracketedButtonContext) -> (matched: Bool, idx: String.Index, charIndex: Int) {
    let ch = ctx.line[ctx.idx]
    guard ch == "[", let closeIdx = ctx.line[ctx.idx...].firstIndex(of: "]") else { return (false, ctx.idx, ctx.charIndex) }
    let innerStart = ctx.line.index(after: ctx.idx)
    let inner = String(ctx.line[innerStart ..< closeIdx]).trimmingCharacters(in: .whitespaces)
    let length = ctx.line.distance(from: ctx.idx, to: closeIdx) + 1 // inclusive
    let col = ctx.startCol + ctx.charIndex
    let button = OverlayButton(label: inner, row: ctx.row, col: col, length: length, action: .init(fromLabel: inner))
    ctx.layer.pointee.buttons.append(button)
    var kIdx = ctx.idx
    var kCharIndex = ctx.charIndex
    while kIdx <= closeIdx {
        placeChar(&ctx.layer.pointee, char: ctx.line[kIdx], row: ctx.row, col: ctx.startCol + kCharIndex, fgColor: ctx.fgColor, rows: ctx.rows, cols: ctx.cols)
        kCharIndex += 1
        kIdx = ctx.line.index(after: kIdx)
    }
    let newIdx = ctx.line.index(after: closeIdx)
    let newCharIndex = ctx.charIndex + length
    return (true, newIdx, newCharIndex)
}

// Helper: place characters for a single line and register bracketed buttons
private func processLine(_ layer: inout ScreenLayer, line: String, row: Int, startCol: Int, fgColor: Color, rows: Int, cols: Int) {
    // Obtain a single stable pointer for the duration of processing this line.
    withUnsafeMutablePointer(to: &layer) { layerPtr in
        var idx = line.startIndex
        var charIndex = 0
        while idx < line.endIndex {
            var ctx = BracketedButtonContext(layer: layerPtr, line: line, idx: idx, charIndex: charIndex, row: row, startCol: startCol, fgColor: fgColor, rows: rows, cols: cols)
            let (matched, newIdx, newCharIndex) = tryProcessBracketedButton(&ctx)
            if matched {
                idx = newIdx
                charIndex = newCharIndex
                continue
            }
            // Use the pointee inside the pointer scope to place a single char.
            placeChar(&layerPtr.pointee, char: line[idx], row: row, col: startCol + charIndex, fgColor: fgColor, rows: rows, cols: cols)
            idx = line.index(after: idx)
            charIndex += 1
        }
    }
}

// OverlayFactory is responsible for creating overlays.
// It provides a method to generate a centered text layer
// for any given overlay kind, with customizable appearance.
enum OverlayFactory {
    static func make(kind: OverlayKind,
                     rows: Int = Settings.rows - 2,
                     cols: Int = Settings.cols,
                     fgColor: Color = Colors.theme.overlayForeground) -> ScreenLayer
    {
        // Use centered overlay (preserves each line exactly)
        let text = kind.message
        var layer = centeredOverlayLayer(from: text, rows: rows, cols: cols, fgColor: fgColor)
        // Record overlay kind on the layer so UI/event handlers can inspect it
        layer.overlayKind = kind
        return layer
    }

    // Per-overlay factory helpers (moved from separate overlay files)
    static func makeWelcomeOverlay(rows: Int = Settings.rows - 2, cols: Int = Settings.cols, fgColor: Color = Colors.theme.overlayForeground) -> ScreenLayer {
        // Use the centralized helper which accepts a pre-filled message string.
        makeCenteredOverlay(from: Messages.welcomeMessage, rows: rows, cols: cols, fgColor: fgColor)
    }

    static func makeHelpOverlay(rows: Int = Settings.rows - 2, cols: Int = Settings.cols, fgColor: Color = Colors.theme.overlayForeground) -> ScreenLayer {
        makeCenteredOverlay(from: Messages.helpMessage, rows: rows, cols: cols, fgColor: fgColor)
    }

    static func makeQuitOverlay(rows: Int = Settings.rows - 2, cols: Int = Settings.cols, fgColor: Color = Colors.theme.overlayForeground) -> ScreenLayer {
        makeCenteredOverlay(from: Messages.quitMessage, rows: rows, cols: cols, fgColor: fgColor)
    }

    static func makeAboutOverlay(rows: Int = Settings.rows - 2, cols: Int = Settings.cols, fgColor: Color = Colors.theme.overlayForeground) -> ScreenLayer {
        makeCenteredOverlay(from: Messages.aboutMessage, rows: rows, cols: cols, fgColor: fgColor)
    }

    static func makeSearchOverlay(rows: Int = Settings.rows - 2, cols: Int = Settings.cols, fgColor: Color = Colors.theme.overlayForeground) -> ScreenLayer {
        makeCenteredOverlay(from: Messages.searchMessage, rows: rows, cols: cols, fgColor: fgColor)
    }

    static func makeGotoOverlay(rows: Int = Settings.rows - 2, cols: Int = Settings.cols, fgColor: Color = Colors.theme.overlayForeground) -> ScreenLayer {
        makeCenteredOverlay(from: Messages.gotoMessage, rows: rows, cols: cols, fgColor: fgColor)
    }

    static func makeMenuOverlay(rows: Int = Settings.rows - 2, cols: Int = Settings.cols, fgColor: Color = Colors.theme.overlayForeground) -> ScreenLayer {
        makeCenteredOverlay(from: Messages.menuMessage, rows: rows, cols: cols, fgColor: fgColor)
    }

    // Add missing library overlay factory
    static func makeLibraryOverlay(rows: Int = Settings.rows - 2, cols: Int = Settings.cols, fgColor: Color = Colors.theme.overlayForeground) -> ScreenLayer {
        makeCenteredOverlay(from: Messages.libraryMessage, rows: rows, cols: cols, fgColor: fgColor)
    }

    static func makeStatisticsOverlay(rows: Int = Settings.rows - 2, cols: Int = Settings.cols, fgColor: Color = Colors.theme.overlayForeground) -> ScreenLayer {
        // Statistics overlay contains ASCII box art: preserve whitespace so borders align
        makeCenteredOverlay(from: Messages.statisticsMessage, rows: rows, cols: cols, fgColor: fgColor)
    }

    // Unified helper: create a ScreenLayer from a message string (placeholders should be applied by caller).
    static func makeCenteredOverlay(from message: String, rows: Int = Settings.rows - 2, cols: Int = Settings.cols, fgColor: Color = Colors.theme.overlayForeground) -> ScreenLayer {
        centeredOverlayLayer(from: message, rows: rows, cols: cols, fgColor: fgColor)
    }

    // Action-bar items: per-overlay action bar labels and a dispatcher used by the UI/tests.
    static func actionBarItems(for kind: OverlayKind) -> [String] {
        switch kind {
        case .help: return helpActionBarItems()
        case .welcome: return welcomeActionBarItems()
        case .quit: return quitActionBarItems()
        case .about: return aboutActionBarItems()
        case .search: return searchActionBarItems()
        case .goto: return gotoActionBarItems()
        case .menu: return menuActionBarItems()
        case .statistics: return statisticsActionBarItems()
        case .library: return libraryActionBarItems()
        }
    }

    static func helpActionBarItems() -> [String] {
        ["Help", Settings.wordWrapLabel, "Open", "Search", "Goto", "Bookm", "Start", "End", "Menu", "Quit"]
    }

    static func welcomeActionBarItems() -> [String] {
        // For welcome overlay keep the default menu layout
        ActionBar.defaultMenuItems
    }

    static func quitActionBarItems() -> [String] {
        ["Yes", "No", "Cancel"]
    }

    static func aboutActionBarItems() -> [String] {
        ["OK", "Menu"]
    }

    static func searchActionBarItems() -> [String] {
        ["Find", "Next", "Prev", "Close"]
    }

    static func gotoActionBarItems() -> [String] {
        ["Goto", "Close"]
    }

    static func menuActionBarItems() -> [String] {
        ActionBar.defaultMenuItems
    }

    static func statisticsActionBarItems() -> [String] {
        ["Close"]
    }

    static func libraryActionBarItems() -> [String] {
        ActionBar.defaultMenuItems
    }

    // Create a statistics overlay using live document data (fills placeholders)
    static func makeStatisticsOverlay(document: TextDocument, rows: Int = Settings.rows - 2, cols: Int = Settings.cols, fgColor: Color = Colors.theme.overlayForeground) -> ScreenLayer {
        let stats = document.statistics()
        let formatter: NumberFormatter = {
            let f = NumberFormatter()
            f.numberStyle = .decimal
            f.groupingSeparator = ","
            f.usesGroupingSeparator = true
            f.locale = Locale.current
            return f
        }()
        func fmt(_ n: Int) -> String { formatter.string(from: NSNumber(value: n)) ?? "\(n)" }
        let replacements: [String: String] = [
            "%totalLines%": fmt(stats.totalLines),
            "%totalWords%": fmt(stats.totalWords),
            "%totalChars%": fmt(stats.totalCharacters),
            "%byteSize%": fmt(stats.byteSize),
            "%avgLineLength%": fmt(stats.averageLineLength),
            "%longestLineLength%": fmt(stats.longestLineLength),
            "%shortestLineLength%": fmt(stats.shortestLineLength),
        ]
        let text = Messages.substituteFixedWidthPlaceholders(Messages.statisticsMessage, replacements: replacements)
        return makeCenteredOverlay(from: text, rows: rows, cols: cols, fgColor: fgColor)
    }
}
