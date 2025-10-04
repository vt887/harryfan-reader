//
//  Overlays.swift
//  harryfan-reader
//
//  Created by @vt887 on 10/01/25.
//

import SwiftUI

// OverlayKind defines the different types of overlays
// that can be displayed in the application, such as
// welcome, help, custom messages, or file text previews.
enum OverlayKind: Equatable {
    case welcome
    case help
    case custom(String)
    case fileText(String)

    // Returns the message string associated with each overlay kind.
    // This is used to display the appropriate content in the overlay.
    var message: String {
        switch self {
        case .welcome: Messages.welcomeMessage
        case .help: Messages.helpMessage
        case let .custom(s): s
        case let .fileText(s): s
        }
    }
}

// OverlayFactory is responsible for creating overlays.
// It provides a method to generate a centered text layer
// for any given overlay kind, with customizable appearance.
enum OverlayFactory {
    static func make(kind: OverlayKind,
                     rows: Int = AppSettings.rows - 2,
                     cols: Int = AppSettings.cols,
                     fgColor: Color = Colors.theme.foreground) -> ScreenLayer
    {
        // Prepare the text to be displayed in the overlay.
        // The text is centered within the specified rows and columns.
        let text = kind.message
        return centeredLayer(message: text, rows: rows, cols: cols, fgColor: fgColor)
    }

    // Creates a ScreenLayer with the message centered both vertically and horizontally.
    // Each character is placed in the correct position, and the foreground color is applied.
    private static func centeredLayer(message: String,
                                      rows: Int,
                                      cols: Int,
                                      fgColor: Color) -> ScreenLayer
    {
        var layer = ScreenLayer(rows: rows, cols: cols)
        let lines = message.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        let totalLines = lines.count
        let verticalPadding = max(0, (rows - totalLines) / 2)
        for (i, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let padding = max(0, (cols - trimmed.count) / 2)
            for (j, char) in trimmed.enumerated() {
                let row = verticalPadding + i
                let col = padding + j
                if row < rows, col < cols {
                    layer[row, col] = ScreenCell(char: char, fgColor: fgColor, bgColor: nil)
                }
            }
        }
        return layer
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
    // `addOverlay(.custom("..."))` or `addOverlay(kind: .fileText(...))`.
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
