//
//  FontManager.swift
//  harryfan-reader
//
//  Created by @vt887 on 9/1/25.
//

import AppKit
import Foundation
import SwiftUI

// Manages font loading, parsing, and bitmap lookup
final class FontManager: ObservableObject {
    // Currently selected font
    @Published var currentFont: MSDOSFont
    // Current font size
    @Published var fontSize: CGFloat = 16.0
    // List of available font names
    @Published var availableFonts: [String] = []

    // Raw font data
    private var fontData: Data?
    // Cache of character bitmaps
    private var fontCache: [UInt8: [Bool]] = [:]

    // Supported MS-DOS font types
    enum MSDOSFont: String, CaseIterable {
        case vdu8x16 = "vdu.8x16" // Legacy reference

        // Display name for UI
        var displayName: String { rawValue }
    }

    // Initializes FontManager and loads initial font
    init() {
        let initialFont = MSDOSFont(rawValue: AppSettings.fontFileName)
            ?? MSDOSFont(rawValue: AppSettings.defaultFontFileName)
            ?? .vdu8x16
        currentFont = initialFont

        scanForFonts()
        loadFont()
    }

    // Returns URL to user's fonts directory
    private func getUserFontsURL() -> URL {
        let expandedHome = (AppSettings.homeDir as NSString).expandingTildeInPath
        let homeDirURL = URL(fileURLWithPath: expandedHome)
        return homeDirURL.appendingPathComponent("fonts")
    }

    // Scans for available font files
    private func scanForFonts() {
        let fm = FileManager.default
        let userFontsURL = getUserFontsURL()

        if let fontFiles = try? fm.contentsOfDirectory(
            at: userFontsURL,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ) {
            let rawFonts = fontFiles
                .filter { $0.pathExtension == "raw" }
                .map { $0.deletingPathExtension().lastPathComponent }

            availableFonts = rawFonts.isEmpty
                ? [AppSettings.defaultFontFileName]
                : rawFonts
        } else {
            availableFonts = [AppSettings.defaultFontFileName]
        }
    }

    // Loads font data from file
    private func loadFont() {
        var effectiveFont = AppSettings.fontFileName
        var fontURL = findFontURL(for: effectiveFont)

        if fontURL == nil {
            DebugLogger.logWarning("\(effectiveFont).raw not found. Falling back to default: \(AppSettings.defaultFontFileName).raw")
            effectiveFont = AppSettings.defaultFontFileName
            fontURL = findFontURL(for: effectiveFont)
        }

        guard let url = fontURL else {
            DebugLogger.logError("Failed to find any font file.")
            return
        }

        do {
            fontData = try Data(contentsOf: url)
            parseFontData()
            DebugLogger.log("Font loaded from: \(url.path)")

            if currentFont.rawValue != effectiveFont,
               let newFont = MSDOSFont(rawValue: effectiveFont)
            {
                currentFont = newFont
            }
        } catch {
            DebugLogger.logError("Failed to load font: \(error)")
        }
    }

    // Finds font file URL for given font name
    private func findFontURL(for fontName: String) -> URL? {
        let fm = FileManager.default
        let userFontsURL = getUserFontsURL()

        // 1. User fonts (~/.harryfan/fonts)
        let userFontURL = userFontsURL.appendingPathComponent("\(fontName).raw")
        if fm.fileExists(atPath: userFontURL.path) { return userFontURL }

        // 2. Fallbacks: default font
        let defaultUserFont = userFontsURL.appendingPathComponent("\(AppSettings.defaultFontFileName).raw")
        if fm.fileExists(atPath: defaultUserFont.path) { return defaultUserFont }

        #if SWIFT_PACKAGE
            if let url = Bundle.module.url(forResource: AppSettings.defaultFontFileName, withExtension: "raw", subdirectory: "Fonts") {
                return url
            }
        #endif
        if let url = Bundle.module.url(forResource: AppSettings.defaultFontFileName, withExtension: "raw", subdirectory: "Fonts") {
            return url
        }
        return Bundle.main.url(forResource: AppSettings.defaultFontFileName, withExtension: "raw", subdirectory: "Fonts")
    }

    // Parses raw font data into bitmaps
    private func parseFontData() {
        guard let data = fontData else {
            return
        }

        let charHeight = AppSettings.charH
        let charWidth = AppSettings.charW
        let numChars = 256
        let expectedBytes = numChars * charHeight
        let headerSize = max(0, data.count - expectedBytes)

        for charIndex in 0 ..< numChars {
            let charOffset = headerSize + (charIndex * charHeight)
            var bitmap: [Bool] = []

            for row in 0 ..< charHeight {
                if charOffset + row < data.count {
                    let byte = data[charOffset + row]
                    for bit in 0 ..< charWidth {
                        bitmap.append((byte & (1 << (7 - bit))) != 0)
                    }
                } else {
                    bitmap.append(contentsOf: Array(repeating: false, count: charWidth))
                }
            }

            fontCache[UInt8(charIndex)] = bitmap
        }
    }

    // Returns bitmap for given character
    func getCharacterBitmap(for char: Character) -> [Bool]? {
        guard let scalar = char.unicodeScalars.first else {
            return fontCache[0x20] // space
        }

        let cp866Value = convertToCP866(scalar)

        if let bitmap = fontCache[cp866Value] {
            return bitmap
        }

        // Fallback: generate '?' square if unknown
        if fontCache[0x3F] == nil {
            fontCache[0x3F] = Self.makeFallbackGlyph()
        }
        return fontCache[0x3F]
    }

    // Generates fallback glyph bitmap
    private static func makeFallbackGlyph() -> [Bool] {
        let width = AppSettings.charW, height = AppSettings.charH
        var bitmap: [Bool] = []
        for row in 0 ..< height {
            for col in 0 ..< width {
                let isBorder = row == 0 || row == height - 1 || col == 0 || col == width - 1
                bitmap.append(isBorder)
            }
        }
        return bitmap
    }

    // Converts Unicode scalar to CP866 byte
    private func convertToCP866(_ unicodeScalar: UnicodeScalar) -> UInt8 {
        let value = Int(unicodeScalar.value)
        if value <= 0x7F { return UInt8(value) }
        // Find the index of the Unicode point in the mapping array
        if let index = unicodePoints.firstIndex(of: unicodeScalar.value) {
            return UInt8(index)
        }
        return 0x3F // fallback to '?'
    }

    // Creates and returns a custom NSFont using the current font name and size
    func createCustomFont() -> NSFont? {
        let fontName = currentFont.rawValue.replacingOccurrences(of: ".raw", with: "")
        // Try to create the custom font first
        if let customFont = NSFont(name: fontName, size: fontSize) {
            return customFont
        }
        // Fall back to system monospaced font if custom font isn't available
        return NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
    }
}
