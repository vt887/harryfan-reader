//
//  MessageBuilder.swift
//  harryfan-reader
//
//  Created by @vt887 on 10/12/25.
//

import Foundation
import SwiftUI

/// Helper class to build templated messages (for overlays) from templates containing
/// fixed-width placeholders like "%totalLines%". This centralizes formatting
/// and placeholder substitution for statistics and other overlays.
enum MessageBuilder {
    enum Alignment {
        case left // value then spaces
        case right // spaces then value
        case center
    }

    /// Typed replacement value: either an integer (to be formatted) or a raw string.
    enum TokenValue {
        case int(Int)
        case string(String)
    }

    /// Build a message by substituting fixed-width placeholders contained in `template`.
    /// - Parameters:
    ///   - template: source template containing tokens (e.g. "%totalLines%")
    ///   - replacements: mapping token -> TokenValue
    ///   - globalAlignment: default alignment used when a token-specific alignment isn't provided
    ///   - alignments: optional per-token alignment overrides
    ///   - widths: optional explicit width to use for a token (if absent, token.count is used)
    ///   - numberFormatter: optional formatter for integer values (defaults to grouped decimal)
    /// - Returns: resulting string with tokens replaced preserving overall column layout
    static func buildMessage(template: String,
                             replacements: [String: TokenValue],
                             globalAlignment: Alignment = .left,
                             alignments: [String: Alignment]? = nil,
                             widths: [String: Int]? = nil,
                             numberFormatter: NumberFormatter? = nil) -> String
    {
        let formatter: NumberFormatter = numberFormatter ?? {
            let f = NumberFormatter()
            f.numberStyle = .decimal
            f.groupingSeparator = ","
            f.usesGroupingSeparator = true
            f.locale = Locale.current
            return f
        }()

        func stringFor(_ value: TokenValue) -> String {
            switch value {
            case let .int(n): formatter.string(from: NSNumber(value: n)) ?? "\(n)"
            case let .string(s): s
            }
        }

        // Process line-by-line to prevent cross-line token matching surprises
        let lines = template.components(separatedBy: "\n")
        var outLines: [String] = []
        for var line in lines {
            // We iterate replacements in stable order (sorted keys) to keep deterministic output
            for key in replacements.keys.sorted() {
                guard let tokenValue = replacements[key] else { continue }
                let replacementStr = stringFor(tokenValue)
                // Token appearance length: either explicit width override or token.count
                let tokenLen = widths?[key] ?? key.count
                let alignment = alignments?[key] ?? globalAlignment

                // Build the padded/truncated string according to alignment and tokenLen
                let padded: String
                if replacementStr.count >= tokenLen {
                    // truncate if too long
                    switch alignment {
                    case .left:
                        padded = String(replacementStr.prefix(tokenLen))
                    case .right:
                        padded = String(replacementStr.suffix(tokenLen))
                    case .center:
                        let start = max(0, (replacementStr.count - tokenLen) / 2)
                        let idx = replacementStr.index(replacementStr.startIndex, offsetBy: start)
                        padded = String(replacementStr[idx ..< replacementStr.index(idx, offsetBy: tokenLen)])
                    }
                } else {
                    let padCount = tokenLen - replacementStr.count
                    switch alignment {
                    case .left:
                        padded = replacementStr + String(repeating: " ", count: padCount)
                    case .right:
                        padded = String(repeating: " ", count: padCount) + replacementStr
                    case .center:
                        let leftPad = padCount / 2
                        let rightPad = padCount - leftPad
                        padded = String(repeating: " ", count: leftPad) + replacementStr + String(repeating: " ", count: rightPad)
                    }
                }

                // Replace all occurrences of the token key in the line with the padded text
                while let r = line.range(of: key) {
                    line.replaceSubrange(r, with: padded)
                }
            }
            outLines.append(line)
        }

        return outLines.joined(separator: "\n")
    }

    /// Convenience method specialized for the statistics template.
    static func buildStatisticsMessage(from stats: TextDocument.Statistics,
                                       numberFormatter: NumberFormatter? = nil,
                                       alignments: [String: Alignment]? = nil,
                                       widths: [String: Int]? = nil) -> String
    {
        let replacements: [String: TokenValue] = [
            "%totalLines%": .int(stats.totalLines),
            "%totalWords%": .int(stats.totalWords),
            "%totalChars%": .int(stats.totalCharacters),
            "%byteSize%": .int(stats.byteSize),
            "%avgLineLength%": .int(stats.averageLineLength),
            "%longestLineLength%": .int(stats.longestLineLength),
            "%shortestLineLength%": .int(stats.shortestLineLength),
        ]

        return buildMessage(template: Messages.statisticsMessage,
                            replacements: replacements,
                            globalAlignment: .left,
                            alignments: alignments,
                            widths: widths,
                            numberFormatter: numberFormatter)
    }

    /// Build a message for a given OverlayKind using token names without percent markers.
    /// Example: pass ["totalLines": .int(1058)] and it will substitute "%totalLines%" in the template.
    static func buildMessage(for kind: OverlayKind,
                             valuesByName: [String: TokenValue] = [:],
                             globalAlignment: Alignment = .left,
                             alignments: [String: Alignment]? = nil,
                             widths: [String: Int]? = nil,
                             numberFormatter: NumberFormatter? = nil) -> String
    {
        // Transform keys like "totalLines" to "%totalLines%"
        var replacements: [String: TokenValue] = [:]
        for (k, v) in valuesByName {
            let token = "%\(k)%"
            replacements[token] = v
        }
        // Use the message string from Messages (OverlayKind.message)
        let template = kind.message
        return buildMessage(template: template,
                            replacements: replacements,
                            globalAlignment: globalAlignment,
                            alignments: alignments,
                            widths: widths,
                            numberFormatter: numberFormatter)
    }

    /// Build a message for any arbitrary template string using simple name-based keys (without percent markers).
    static func buildMessage(templateKeyed template: String,
                             valuesByName: [String: TokenValue] = [:],
                             globalAlignment: Alignment = .left,
                             alignments: [String: Alignment]? = nil,
                             widths: [String: Int]? = nil,
                             numberFormatter: NumberFormatter? = nil) -> String
    {
        var replacements: [String: TokenValue] = [:]
        for (k, v) in valuesByName {
            replacements["%\(k)%"] = v
        }
        return buildMessage(template: template,
                            replacements: replacements,
                            globalAlignment: globalAlignment,
                            alignments: alignments,
                            widths: widths,
                            numberFormatter: numberFormatter)
    }

    // MARK: - ScreenLayer builders (convenience)

    /// Build a ScreenLayer (centered overlay) for the given OverlayKind using provided values and optional sizing/colors.
    /// - Parameters:
    ///   - kind: overlay kind (will use Messages.* template for that kind)
    ///   - valuesByName: simple-name keyed replacement values (e.g. ["totalLines": .int(1058)])
    ///   - rows: optional number of rows to render (if nil uses Settings.rows - 2)
    ///   - cols: optional number of columns to render (if nil uses Settings.cols)
    ///   - globalAlignment/alignments/widths/numberFormatter: forwarded to buildMessage
    static func buildScreenLayer(for kind: OverlayKind,
                                 valuesByName: [String: TokenValue] = [:],
                                 rows: Int? = nil,
                                 cols: Int? = nil,
                                 messageTitle: String? = nil,
                                 globalAlignment: Alignment = .left,
                                 alignments: [String: Alignment]? = nil,
                                 widths: [String: Int]? = nil,
                                 numberFormatter: NumberFormatter? = nil) -> ScreenLayer
    {
        var values = valuesByName
        if let title = messageTitle, values["title"] == nil {
            values["title"] = .string(title)
        }
        let template = kind.message
        let text = buildMessage(templateKeyed: template,
                                valuesByName: values,
                                globalAlignment: globalAlignment,
                                alignments: alignments,
                                widths: widths,
                                numberFormatter: numberFormatter)
        let r = rows ?? (Settings.rows - 2)
        let c = cols ?? Settings.cols
        let fg = Colors.theme.overlayForeground
        return OverlayFactory.makeCenteredOverlay(from: text, rows: r, cols: c, fgColor: fg)
    }

    /// Overload that accepts a window size in points and computes rows/cols using Settings.charW/charH.
    static func buildScreenLayer(for kind: OverlayKind,
                                 valuesByName: [String: TokenValue] = [:],
                                 windowSize: CGSize,
                                 messageTitle: String? = nil,
                                 globalAlignment: Alignment = .left,
                                 alignments: [String: Alignment]? = nil,
                                 widths: [String: Int]? = nil,
                                 numberFormatter: NumberFormatter? = nil) -> ScreenLayer
    {
        // Convert window size in points to text rows/cols using character dimensions
        let cols = max(1, Int(windowSize.width) / Settings.charW)
        let rows = max(1, Int(windowSize.height) / Settings.charH)
        return buildScreenLayer(for: kind,
                                valuesByName: valuesByName,
                                rows: rows,
                                cols: cols,
                                messageTitle: messageTitle,
                                globalAlignment: globalAlignment,
                                alignments: alignments,
                                widths: widths,
                                numberFormatter: numberFormatter)
    }

    /// Build a ScreenLayer for an arbitrary template string (useful for one-off messages).
    static func buildScreenLayer(fromTemplate template: String,
                                 valuesByName: [String: TokenValue] = [:],
                                 rows: Int? = nil,
                                 cols: Int? = nil,
                                 messageTitle: String? = nil,
                                 globalAlignment: Alignment = .left,
                                 alignments: [String: Alignment]? = nil,
                                 widths: [String: Int]? = nil,
                                 numberFormatter: NumberFormatter? = nil) -> ScreenLayer
    {
        var values = valuesByName
        if let title = messageTitle, values["title"] == nil { values["title"] = .string(title) }
        let text = buildMessage(templateKeyed: template,
                                valuesByName: values,
                                globalAlignment: globalAlignment,
                                alignments: alignments,
                                widths: widths,
                                numberFormatter: numberFormatter)
        let r = rows ?? (Settings.rows - 2)
        let c = cols ?? Settings.cols
        let fg = Colors.theme.overlayForeground
        return OverlayFactory.makeCenteredOverlay(from: text, rows: r, cols: c, fgColor: fg)
    }

    /// Overload that accepts a window size (CGSize) to auto-compute rows/cols for an arbitrary template.
    static func buildScreenLayer(fromTemplate template: String,
                                 valuesByName: [String: TokenValue] = [:],
                                 windowSize: CGSize,
                                 messageTitle: String? = nil,
                                 globalAlignment: Alignment = .left,
                                 alignments: [String: Alignment]? = nil,
                                 widths: [String: Int]? = nil,
                                 numberFormatter: NumberFormatter? = nil) -> ScreenLayer
    {
        let cols = max(1, Int(windowSize.width) / Settings.charW)
        let rows = max(1, Int(windowSize.height) / Settings.charH)
        return buildScreenLayer(fromTemplate: template,
                                valuesByName: valuesByName,
                                rows: rows,
                                cols: cols,
                                messageTitle: messageTitle,
                                globalAlignment: globalAlignment,
                                alignments: alignments,
                                widths: widths,
                                numberFormatter: numberFormatter)
    }
}
