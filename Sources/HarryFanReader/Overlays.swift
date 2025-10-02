//  Overlays.swift
//  harryfan-reader
//
//  Unified overlay system: types, factory, and manager for text overlays.
//
//  Provides overlay types, factory for creating centered text overlays,
//  and manager for overlay state and opacity control.

import SwiftUI

// MARK: - Overlay Types

enum OverlayKind: Equatable {
    case welcome
    case help
    case custom(String)
    case fileText(String)

    var message: String {
        switch self {
        case .welcome: Messages.welcomeMessage
        case .help: Messages.helpMessage
        case let .custom(s): s
        case let .fileText(s): s
        }
    }
}

// MARK: - Overlay Factory

enum OverlayFactory {
    static func make(kind: OverlayKind,
                     rows: Int = AppSettings.rows - 2,
                     cols: Int = AppSettings.cols,
                     fgColor: Color = Colors.theme.foreground) -> ScreenLayer
    {
        let text = kind.message
        return centeredLayer(message: text, rows: rows, cols: cols, fgColor: fgColor)
    }

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

// MARK: - Overlay Manager

final class OverlayManager {
    private(set) var overlays: [OverlayKind] = []
    private(set) var opacity: Double = 1.0

    func addOverlay(_ kind: OverlayKind) {
        if !overlays.contains(kind) {
            overlays.append(kind)
        }
    }

    func removeOverlay(_ kind: OverlayKind) {
        overlays.removeAll { $0 == kind }
    }

    func removeAll() {
        overlays.removeAll()
    }

    func setOpacity(_ value: Double) {
        opacity = min(max(value, 0.0), 1.0)
    }

    func getOpacity() -> Double {
        opacity
    }
}
