//
// FontManager.swift
// harryfan-reader
//
// Created by Vad Tymoshyk on 9/1/25.
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
            options: .skipsHiddenFiles,
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
            print("\(effectiveFont).raw not found. Falling back to default: \(AppSettings.defaultFontFileName).raw")
            effectiveFont = AppSettings.defaultFontFileName
            fontURL = findFontURL(for: effectiveFont)
        }

        guard let url = fontURL else {
            print("Failed to find any font file.")
            return
        }

        do {
            fontData = try Data(contentsOf: url)
            parseFontData()
            print("Font loaded from: \(url.path)")

            if currentFont.rawValue != effectiveFont,
               let newFont = MSDOSFont(rawValue: effectiveFont)
            {
                currentFont = newFont
            }
        } catch {
            print("Failed to load font: \(error)")
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
        return Bundle.main.url(forResource: AppSettings.defaultFontFileName, withExtension: "raw", subdirectory: "Fonts")
    }

    // Parses raw font data into bitmaps
    private func parseFontData() {
        guard let data = fontData else { return }

        let charHeight = 16
        let charWidth = 8
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

    // CP866 Unicode code points table
    private static let cp866UnicodePoints: [UInt32] = [
        0x0000, 0x0001, 0x0002, 0x0003, 0x0004, 0x0005, 0x0006, 0x0007,
        0x0008, 0x0009, 0x000A, 0x000B, 0x000C, 0x000D, 0x000E, 0x000F,
        0x0010, 0x0011, 0x0012, 0x0013, 0x0014, 0x0015, 0x0016, 0x0017,
        0x0018, 0x0019, 0x001A, 0x001B, 0x001C, 0x001D, 0x001E, 0x001F,
        0x0020, 0x0021, 0x0022, 0x0023, 0x0024, 0x0025, 0x0026, 0x0027,
        0x0028, 0x0029, 0x002A, 0x002B, 0x002C, 0x002D, 0x002E, 0x002F,
        0x0030, 0x0031, 0x0032, 0x0033, 0x0034, 0x0035, 0x0036, 0x0037,
        0x0038, 0x0039, 0x003A, 0x003B, 0x003C, 0x003D, 0x003E, 0x003F,
        0x0040, 0x0041, 0x0042, 0x0043, 0x0044, 0x0045, 0x0046, 0x0047,
        0x0048, 0x0049, 0x004A, 0x004B, 0x004C, 0x004D, 0x004E, 0x004F,
        0x0050, 0x0051, 0x0052, 0x0053, 0x0054, 0x0055, 0x0056, 0x0057,
        0x0058, 0x0059, 0x005A, 0x005B, 0x005C, 0x005D, 0x005E, 0x005F,
        0x0060, 0x0061, 0x0062, 0x0063, 0x0064, 0x0065, 0x0066, 0x0067,
        0x0068, 0x0069, 0x006A, 0x006B, 0x006C, 0x006D, 0x006E, 0x006F,
        0x0070, 0x0071, 0x0072, 0x0073, 0x0074, 0x0075, 0x0076, 0x0077,
        0x0078, 0x0079, 0x007A, 0x007B, 0x007C, 0x007D, 0x007E, 0x007F,
        0x0410, 0x0411, 0x0412, 0x0413, 0x0414, 0x0415, 0x0416, 0x0417,
        0x0418, 0x0419, 0x041A, 0x041B, 0x041C, 0x041D, 0x041E, 0x041F,
        0x0420, 0x0421, 0x0422, 0x0423, 0x0424, 0x0425, 0x0426, 0x0427,
        0x0428, 0x0429, 0x042A, 0x042B, 0x042C, 0x042D, 0x042E, 0x042F,
        0x0430, 0x0431, 0x0432, 0x0433, 0x0434, 0x0435, 0x0436, 0x0437,
        0x0438, 0x0439, 0x043A, 0x043B, 0x043C, 0x043D, 0x043E, 0x043F,
        0x2591, 0x2592, 0x2593, 0x2502, 0x2524, 0x2561, 0x2562, 0x2556,
        0x2555, 0x2563, 0x2551, 0x2557, 0x255D, 0x255C, 0x255B, 0x2510,
        0x2514, 0x2534, 0x252C, 0x251C, 0x2500, 0x253C, 0x255E, 0x255F,
        0x255A, 0x2554, 0x2569, 0x2566, 0x2560, 0x2550, 0x256C, 0x2567,
        0x2568, 0x2564, 0x2565, 0x2559, 0x2558, 0x2552, 0x2553, 0x256B,
        0x256A, 0x2518, 0x250C, 0x2588, 0x2584, 0x258C, 0x2590, 0x2580,
        0x0440, 0x0441, 0x0442, 0x0443, 0x0444, 0x0445, 0x0446, 0x0447,
        0x0448, 0x0449, 0x044A, 0x044B, 0x044C, 0x044D, 0x044E, 0x044F,
        0x0401, 0x0451, 0x0404, 0x0454, 0x0407, 0x0457, 0x040E, 0x045E,
        0x00B0, 0x2219, 0x00B7, 0x221A, 0x2116, 0x00A4, 0x25A0, 0x00A0,
    ]

    // Maps Unicode code points to CP866 bytes
    private static let unicodeToCP866: [UInt32: UInt8] = {
        var map = [UInt32: UInt8]()
        for (byte, codePoint) in cp866UnicodePoints.enumerated() {
            map[codePoint] = UInt8(byte)
        }
        return map
    }()

    // Converts Unicode scalar to CP866 byte
    private func convertToCP866(_ unicodeScalar: UnicodeScalar) -> UInt8 {
        let value = unicodeScalar.value
        if value <= 0x7F { return UInt8(value) }
        return Self.unicodeToCP866[value] ?? 0x3F
    }

    // Returns system monospaced font as fallback
    func createCustomFont() -> NSFont {
        NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
    }
}
