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
        }
    }
}

// Utility to create a centered overlay layer from a string
// Made internal so other overlay files can reuse this implementation
func centeredOverlayLayer(from message: String, rows: Int, cols: Int, fgColor: Color) -> ScreenLayer {
    var layer = ScreenLayer(rows: rows, cols: cols)
    let lines = message.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
    let totalLines = lines.count
    let verticalPadding = max(0, (rows - totalLines) / 2)
    for (i, line) in lines.enumerated() {
        // Trim only for measurement; we already removed common indentation
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let padding = max(0, (cols - trimmed.count) / 2)
        let startCol = padding

        // First: fill the overlay background for this trimmed region so the overlay
        // shows overlayBackground even where characters are spaces.
        let endCol = startCol + max(0, trimmed.count - 1)
        if verticalPadding + i < rows {
            for c in startCol ... min(endCol, cols - 1) where c >= 0 {
                layer[verticalPadding + i, c] = ScreenCell(char: " ", fgColor: fgColor, bgColor: Colors.theme.overlayBackground)
            }
        }

        // Scan trimmed string for bracketed button tokens and also place characters
        var idx = trimmed.startIndex
        var charIndex = 0
        while idx < trimmed.endIndex {
            let ch = trimmed[idx]
            // If we find an opening bracket, attempt to find a matching closing bracket
            if ch == "[" {
                if let closeIdx = trimmed[idx...].firstIndex(of: "]") {
                    // Extract inside label
                    let innerStart = trimmed.index(after: idx)
                    let inner = String(trimmed[innerStart ..< closeIdx]).trimmingCharacters(in: .whitespaces)
                    let j = charIndex
                    let length = trimmed.distance(from: idx, to: closeIdx) + 1 // inclusive
                    let row = verticalPadding + i
                    let col = startCol + j
                    // Register button on layer
                    let button = OverlayButton(label: inner, row: row, col: col, length: length, action: .init(fromLabel: inner))
                    layer.buttons.append(button)
                    // Place all characters from idx..closeIdx into grid (with overlay bg)
                    var kIdx = idx
                    var kCharIndex = j
                    while kIdx <= closeIdx {
                        let writeRow = verticalPadding + i
                        let writeCol = startCol + kCharIndex
                        if writeRow < rows, writeCol < cols {
                            layer[writeRow, writeCol] = ScreenCell(char: trimmed[kIdx], fgColor: fgColor, bgColor: Colors.theme.overlayBackground)
                        }
                        kCharIndex += 1
                        kIdx = trimmed.index(after: kIdx)
                    }
                    // Advance idx and charIndex past the bracketed token
                    idx = trimmed.index(after: closeIdx)
                    charIndex += length
                    continue
                }
            }
            // Normal character placement (respect overlay background)
            let writeRow = verticalPadding + i
            let writeCol = startCol + charIndex
            if writeRow < rows, writeCol < cols {
                layer[writeRow, writeCol] = ScreenCell(char: ch, fgColor: fgColor, bgColor: Colors.theme.overlayBackground)
            }
            idx = trimmed.index(after: idx)
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
        // Default behavior: use centeredOverlayLayer built from the overlay's message
        let text = kind.message
        var layer = centeredOverlayLayer(from: text, rows: rows, cols: cols, fgColor: fgColor)
        // Record overlay kind on the layer so UI/event handlers can inspect it
        layer.overlayKind = kind
        return layer
    }

    /// Return the action-bar items to display for a given overlay kind.
    static func actionBarItems(for _: OverlayKind) -> [String] {
        ActionBar.defaultMenuItems
    }

    // NOTE: per-overlay helpers previously lived in separate files (e.g. HelpOverlay.swift).
    // They've been consolidated here to centralize overlay creation and avoid scattering
    // small implementations across multiple files.

    // Per-overlay factory helpers (moved from separate overlay files)
    static func makeWelcomeOverlay(rows: Int = Settings.rows - 2, cols: Int = Settings.cols, fgColor: Color = Colors.theme.overlayForeground) -> ScreenLayer {
        let message = Messages.welcomeMessage
        return centeredOverlayLayer(from: message, rows: rows, cols: cols, fgColor: fgColor)
    }

    static func makeHelpOverlay(rows: Int = Settings.rows - 2, cols: Int = Settings.cols, fgColor: Color = Colors.theme.overlayForeground) -> ScreenLayer {
        let message = Messages.helpMessage
        return centeredOverlayLayer(from: message, rows: rows, cols: cols, fgColor: fgColor)
    }

    static func makeQuitOverlay(rows: Int = Settings.rows - 2, cols: Int = Settings.cols, fgColor: Color = Colors.theme.overlayForeground) -> ScreenLayer {
        let message = Messages.quitMessage
        return centeredOverlayLayer(from: message, rows: rows, cols: cols, fgColor: fgColor)
    }

    static func makeAboutOverlay(rows: Int = Settings.rows - 2, cols: Int = Settings.cols, fgColor: Color = Colors.theme.overlayForeground) -> ScreenLayer {
        let message = Messages.aboutMessage
        return centeredOverlayLayer(from: message, rows: rows, cols: cols, fgColor: fgColor)
    }

    static func makeSearchOverlay(rows: Int = Settings.rows - 2, cols: Int = Settings.cols, fgColor: Color = Colors.theme.overlayForeground) -> ScreenLayer {
        let message = Messages.searchMessage
        return centeredOverlayLayer(from: message, rows: rows, cols: cols, fgColor: fgColor)
    }

    static func makeGotoOverlay(rows: Int = Settings.rows - 2, cols: Int = Settings.cols, fgColor: Color = Colors.theme.overlayForeground) -> ScreenLayer {
        let message = Messages.gotoMessage
        return centeredOverlayLayer(from: message, rows: rows, cols: cols, fgColor: fgColor)
    }

    static func makeMenuOverlay(rows: Int = Settings.rows - 2, cols: Int = Settings.cols, fgColor: Color = Colors.theme.overlayForeground) -> ScreenLayer {
        let message = Messages.menuMessage
        return centeredOverlayLayer(from: message, rows: rows, cols: cols, fgColor: fgColor)
    }

    // Per-overlay action bar item helpers
    static func welcomeActionBarItems(cols _: Int = Settings.cols) -> [String] { ActionBar.defaultMenuItems }
    static func helpActionBarItems(cols _: Int = Settings.cols) -> [String] { ActionBar.defaultMenuItems }
    static func quitActionBarItems(cols _: Int = Settings.cols) -> [String] { ActionBar.defaultMenuItems }
    static func aboutActionBarItems(cols _: Int = Settings.cols) -> [String] { ActionBar.defaultMenuItems }
    static func searchActionBarItems(cols _: Int = Settings.cols) -> [String] { ActionBar.defaultMenuItems }
    static func gotoActionBarItems(cols _: Int = Settings.cols) -> [String] { ActionBar.defaultMenuItems }
    static func menuActionBarItems(cols _: Int = Settings.cols) -> [String] { ActionBar.defaultMenuItems }
}

// OverlayManager manages the stack of overlays currently displayed.
// It allows adding, removing, and clearing overlays, as well as
// controlling the opacity of the overlay layer.
final class OverlayManager: ObservableObject {
    // Published properties so SwiftUI views observing this manager
    // will update when overlays or opacity change.
    @Published private(set) var overlays: [OverlayKind] = []
    @Published private(set) var opacity: Double = 1.0

    // Adds a new overlay if it is not already present. Use either
    // `addOverlay(.custom("..."))` to add a custom multi-line overlay.
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

    // Sets the opacity for the overlay layer. The value is clamped
    // between 0.0 and 1.0.
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
