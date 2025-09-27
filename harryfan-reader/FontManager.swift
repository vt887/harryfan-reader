//
//  FontManager.swift
//  harryfan-reader
//
//  Created by Vad Tymoshyk on 9/1/25.
//

import AppKit
import Foundation
import SwiftUI

class FontManager: ObservableObject {
    @Published var currentFont: MSDOSFont = .vdu8x16
    @Published var fontSize: CGFloat = 16.0
    @Published var availableFonts: [String] = [] // New published property

    enum MSDOSFont: String, CaseIterable {
        case vdu8x16 = "VDU 8x16"

        var displayName: String {
            rawValue
        }
    }

    private var fontData: Data?
    private var fontCache: [UInt8: [Bool]] = [:]

    init() {
        scanForFonts()
        loadFont()
    }

    private func scanForFonts() {
        let fm = FileManager.default
        #if SWIFT_PACKAGE
        guard let fontsURL = Bundle.module.resourceURL?.appendingPathComponent("Fonts") else { return }
        #else
        guard let bundleURL = Bundle.main.resourceURL else { return }
        let fontsURL = bundleURL.appendingPathComponent("Fonts")
        #endif

        do {
            let fileURLs = try fm.contentsOfDirectory(at: fontsURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            self.availableFonts = fileURLs.filter { $0.pathExtension == "raw" }.map { $0.deletingPathExtension().lastPathComponent }
        } catch {
            print("Failed to scan for fonts: \(error)")
        }
    }

    private func loadFont() {
        // Locate the font file packaged as a resource
        var fontURL: URL?

        // Prefer SwiftPM resource bundle if available
        #if SWIFT_PACKAGE
            if let url = Bundle.module.url(forResource: "vdu.8x16", withExtension: "raw", subdirectory: "Fonts") {
                fontURL = url
            }
        #endif

        // Fallback to main bundle
        if fontURL == nil {
            if let url = Bundle.main.url(forResource: "vdu.8x16", withExtension: "raw", subdirectory: "Fonts") {
                fontURL = url
            }
        }

        // If not found in bundle, try to find it in the current directory
        if fontURL == nil {
            let currentDir = FileManager.default.currentDirectoryPath
            let fullPath = "\(currentDir)/Fonts/vdu.8x16.raw"
            if FileManager.default.fileExists(atPath: fullPath) {
                fontURL = URL(fileURLWithPath: fullPath)
            }
        }

        guard let url = fontURL else {
            print("Failed to find font file.")
            return
        }

        do {
            fontData = try Data(contentsOf: url)
            parseFontData()
            print("Font loaded successfully from: \(url.path)")
        } catch {
            print("Failed to load font: \(error)")
        }
    }

    private func parseFontData() {
        guard let data = fontData else { return }

        // Detect header size automatically for raw 8x16 bitmap fonts: total = header + (256 * 16)
        let charHeight = 16
        let charWidth = 8
        let numChars = 256
        let expectedGlyphBytes = numChars * charHeight
        let headerSize = data.count >= expectedGlyphBytes ? (data.count - expectedGlyphBytes) : 0

        for charIndex in 0 ..< numChars {
            let charOffset = headerSize + (charIndex * charHeight)
            var charBitmap: [Bool] = []

            for row in 0 ..< charHeight {
                if charOffset + row < data.count {
                    let byte = data[charOffset + row]
                    for bit in 0 ..< charWidth {
                        let isSet = (byte & (1 << (7 - bit))) != 0
                        charBitmap.append(isSet)
                    }
                } else {
                    // If data is truncated, fill with empty lines
                    charBitmap.append(contentsOf: Array(repeating: false, count: charWidth))
                }
            }

            fontCache[UInt8(charIndex)] = charBitmap
        }
    }

    func getCharacterBitmap(for char: Character) -> [Bool]? {
        guard let scalar = char.unicodeScalars.first else {
            return fontCache[0x20] // Return space character if no scalar
        }

        let cp866Value = convertToCP866(scalar)
        let bitmap = fontCache[cp866Value]

        if bitmap == nil {
            // Fallback: create a simple square for unknown characters if not already in cache
            if fontCache[0x3F] == nil { // 0x3F is '?'
                var fallbackBitmap: [Bool] = []
                let charHeight = 16 // Assuming these are still 16x8
                let charWidth = 8
                for row in 0 ..< charHeight {
                    for col in 0 ..< charWidth {
                        let isSet = row == 0 || row == charHeight - 1 || col == 0 || col == charWidth - 1
                        fallbackBitmap.append(isSet)
                    }
                }
                fontCache[0x3F] = fallbackBitmap
            }
            return fontCache[0x3F]
        }
        return bitmap
    }

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

    private static let unicodeToCP866: [UInt32: UInt8] = {
        var map = [UInt32: UInt8]()
        for (byte, codePoint) in cp866UnicodePoints.enumerated() {
            map[codePoint] = UInt8(byte)
        }
        return map
    }()

    private func convertToCP866(_ unicodeScalar: UnicodeScalar) -> UInt8 {
        let value = unicodeScalar.value
        // Basic ASCII fast-path
        if value <= 0x7F { return UInt8(value) }
        // Lookup in reverse map; use '?' (0x3F) for unknowns rather than space
        return FontManager.unicodeToCP866[value] ?? 0x3F
    }

    func createCustomFont() -> NSFont {
        // Create a custom font using the bitmap data
        // For now, we'll use a monospaced system font as fallback
        NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
    }
}
