//
//  Overlays.swift
//  harryfan-reader
//
//  Created by @vt887 on 10/01/25.
//

import Foundation
import SwiftUI

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
private func centeredOverlayLayer(from message: String, rows: Int, cols: Int, fgColor: Color) -> ScreenLayer {
    var layer = ScreenLayer(rows: rows, cols: cols)
    let lines = message.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
    let totalLines = lines.count
    let verticalPadding = max(0, (rows - totalLines) / 2)
    for (i, line) in lines.enumerated() {
        // Trim only for measurement; we already removed common indentation
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let padding = max(0, (cols - trimmed.count) / 2)
        let startCol = padding
        for (j, char) in trimmed.enumerated() {
            let row = verticalPadding + i
            let col = startCol + j
            if row < rows, col < cols {
                layer[row, col] = ScreenCell(char: char, fgColor: fgColor, bgColor: nil)
            }
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
                     fgColor: Color = Colors.theme.foreground) -> ScreenLayer
    {
        // Default behavior: use centeredOverlayLayer built from the overlay's message
        let text = kind.message
        return centeredOverlayLayer(from: text, rows: rows, cols: cols, fgColor: fgColor)
    }

    /// Return the action-bar items to display for a given overlay kind.
    static func actionBarItems(for kind: OverlayKind) -> [String] {
        switch kind {
        case .help:
            HelpOverlay.actionBarItems()
        case .welcome:
            WelcomeOverlay.actionBarItems()
        case .quit:
            QuitOverlay.actionBarItems()
        case .about:
            AboutOverlay.actionBarItems()
        case .search:
            SearchOverlay.actionBarItems()
        case .goto:
            GotoOverlay.actionBarItems()
        case .menu:
            MenuOverlay.actionBarItems()
        }
    }
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
