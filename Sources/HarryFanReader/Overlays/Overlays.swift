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
    var startCols: [Int] = []
    var endCols: [Int] = []
    for line in lines {
        let padding = max(0, (cols - line.count) / 2)
        let startCol = padding
        let endCol = startCol + max(0, line.count - 1)
        startCols.append(startCol)
        endCols.append(endCol)
    }

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
        for r in fillTop ... fillBottom {
            for c in fillLeft ... fillRight {
                layer[r, c] = ScreenCell(char: " ", fgColor: fgColor, bgColor: Colors.theme.overlayBackground)
            }
        }
    }

    for (i, line) in lines.enumerated() {
        let padding = max(0, (cols - line.count) / 2)
        let startCol = padding
        var idx = line.startIndex
        var charIndex = 0
        while idx < line.endIndex {
            let ch = line[idx]
            // If we find an opening bracket, attempt to find a matching closing bracket
            if ch == "[" {
                if let closeIdx = line[idx...].firstIndex(of: "]") {
                    // Extract inside label
                    let innerStart = line.index(after: idx)
                    let inner = String(line[innerStart ..< closeIdx]).trimmingCharacters(in: .whitespaces)
                    let j = charIndex
                    let length = line.distance(from: idx, to: closeIdx) + 1 // inclusive
                    let row = verticalPadding + i
                    let col = startCol + j
                    // Register button on layer
                    let button = OverlayButton(label: inner, row: row, col: col, length: length, action: .init(fromLabel: inner))
                    layer.buttons.append(button)
                    // Place all characters from idx..closeIdx into grid
                    var kIdx = idx
                    var kCharIndex = j
                    while kIdx <= closeIdx {
                        let writeRow = verticalPadding + i
                        let writeCol = startCol + kCharIndex
                        if writeRow < rows, writeCol < cols {
                            layer[writeRow, writeCol] = ScreenCell(char: line[kIdx], fgColor: fgColor, bgColor: Colors.theme.overlayBackground)
                        }
                        kCharIndex += 1
                        kIdx = line.index(after: kIdx)
                    }
                    // Advance idx and charIndex past the bracketed token
                    idx = line.index(after: closeIdx)
                    charIndex += length
                    continue
                }
            }
            // Normal character placement
            let writeRow = verticalPadding + i
            let writeCol = startCol + charIndex
            if writeRow < rows, writeCol < cols {
                layer[writeRow, writeCol] = ScreenCell(char: ch, fgColor: fgColor, bgColor: Colors.theme.overlayBackground)
            }
            idx = line.index(after: idx)
            charIndex += 1
        }
    }
    return layer
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

    static func makeStatisticsOverlay(rows: Int = Settings.rows - 2, cols: Int = Settings.cols, fgColor: Color = Colors.theme.overlayForeground) -> ScreenLayer {
        // Statistics overlay contains ASCII box art: preserve whitespace so borders align
        makeCenteredOverlay(from: Messages.statisticsMessage, rows: rows, cols: cols, fgColor: fgColor)
    }

    static func makeLibraryOverlay(rows: Int = Settings.rows - 2, cols: Int = Settings.cols, fgColor: Color = Colors.theme.overlayForeground) -> ScreenLayer {
        makeCenteredOverlay(from: Messages.libraryMessage, rows: rows, cols: cols, fgColor: fgColor)
    }

    // Unified helper: create a ScreenLayer from a message string (placeholders should be applied by caller).
    // If `preserveWhitespace` is true, the message is placed exactly as-is (useful for ASCII boxes).
    static func makeCenteredOverlay(from message: String, rows: Int = Settings.rows - 2, cols: Int = Settings.cols, fgColor: Color = Colors.theme.overlayForeground) -> ScreenLayer {
        // Canonical centered overlay builder (preserves each line exactly).
        centeredOverlayLayer(from: message, rows: rows, cols: cols, fgColor: fgColor)
    }

    // Create a statistics overlay using live document data (fills placeholders)
    static func makeStatisticsOverlay(document: TextDocument, rows: Int = Settings.rows - 2, cols: Int = Settings.cols, fgColor: Color = Colors.theme.overlayForeground) -> ScreenLayer {
        let stats = document.statistics()
        // Format numbers with thousands separators using NumberFormatter
        let formatter: NumberFormatter = {
            let f = NumberFormatter()
            f.numberStyle = .decimal
            f.groupingSeparator = ","
            f.usesGroupingSeparator = true
            f.locale = Locale.current
            return f
        }()

        func fmt(_ n: Int) -> String { formatter.string(from: NSNumber(value: n)) ?? "\(n)" }

        // Prepare formatted values (with grouping separators) and substitute them into the
        // statistics template using fixed-width substitution so box borders do not shift.
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
        let layer = makeCenteredOverlay(from: text, rows: rows, cols: cols, fgColor: fgColor)
        return layer
    }

    // Per-overlay action bar item helpers
    static func actionBarItems(for kind: OverlayKind) -> [String] {
        switch kind {
        case .welcome:
            [
                "Continue",
                "Quit",
            ]
        case .help:
            [
                "Search",
                "Continue",
                "Quit",
            ]
        case .quit:
            [
                "Quit",
            ]
        case .about:
            [
                "Continue",
                "Quit",
            ]
        case .search:
            [
                "Search",
                "Continue",
                "Quit",
            ]
        case .goto:
            [
                "Goto",
                "Continue",
                "Quit",
            ]
        case .menu:
            [
                "Continue",
                "Quit",
            ]
        case .library:
            [
                "Open",
                "Close",
            ]
        case .statistics:
            [
                "Continue",
                "Quit",
            ]
        }
    }

    static func libraryActionBarItems() -> [String] { actionBarItems(for: .library) }

    // Convenience wrappers used by unit tests and call sites that expect per-kind helpers.
    static func helpActionBarItems() -> [String] { actionBarItems(for: .help) }
    static func welcomeActionBarItems() -> [String] { actionBarItems(for: .welcome) }
    static func quitActionBarItems() -> [String] { actionBarItems(for: .quit) }
    static func aboutActionBarItems() -> [String] { actionBarItems(for: .about) }
    static func searchActionBarItems() -> [String] { actionBarItems(for: .search) }
    static func gotoActionBarItems() -> [String] { actionBarItems(for: .goto) }
    static func menuActionBarItems() -> [String] { actionBarItems(for: .menu) }
    static func statisticsActionBarItems() -> [String] { actionBarItems(for: .statistics) }
}

// OverlayManager manages the stack of overlays currently displayed.
// It allows adding, removing, and clearing overlays, as well as
// controlling the opacity of the overlay layer.
final class OverlayManager: ObservableObject {
    @Published private(set) var overlays: [OverlayKind] = []
    @Published private(set) var opacity: Double = 1.0

    // Adds a new overlay if it is not already present.
    func addOverlay(_ kind: OverlayKind) {
        if !overlays.contains(kind) {
            overlays.append(kind)
        }
    }

    // Labeled overload to match call sites that use `kind:` label.
    func addOverlay(kind: OverlayKind) { addOverlay(kind) }

    // Removes the specified overlay kind from the stack.
    func removeOverlay(_ kind: OverlayKind) {
        overlays.removeAll { $0 == kind }
    }

    // Labeled overload to match call sites that use `kind:` label.
    func removeOverlay(kind: OverlayKind) { removeOverlay(kind) }

    // Removes all overlays from the stack.
    func removeAll() { overlays.removeAll() }

    // Sets the opacity for the overlay layer. The value is clamped between 0.0 and 1.0.
    func setOpacity(_ value: Double) {
        opacity = min(max(value, 0.0), 1.0)
    }

    // Returns the current opacity value for overlays.
    func getOpacity() -> Double { opacity }

    /// Removes all overlays of type .help from the stack.
    func removeHelpOverlay() {
        overlays.removeAll { $0 == .help }
    }
}
