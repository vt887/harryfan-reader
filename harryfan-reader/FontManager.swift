//
//  FontManager.swift
//  harryfan-reader
//
//  Created by Vad Tymoshyk on 9/1/25.
//

import SwiftUI
import Foundation

class FontManager: ObservableObject {
    @Published var currentFont: MSDOSFont = .vdu8x16
    @Published var fontSize: CGFloat = 16.0
    
    enum MSDOSFont: String, CaseIterable {
        case vdu8x16 = "VDU 8x16"
        
        var displayName: String {
            return self.rawValue
        }
    }
    
    private var fontData: Data?
    private var fontCache: [UInt8: [Bool]] = [:]
    
    init() {
        loadFont()
    }
    
    private func loadFont() {
        // Try multiple possible locations for the font file
        let possiblePaths = [
            "vdu.8x16.raw",
            "HarryfanReader/vdu.8x16.raw",
            "Resources/vdu.8x16.raw"
        ]
        
        var fontURL: URL?
        
        for path in possiblePaths {
            if let url = Bundle.main.url(forResource: path.replacingOccurrences(of: ".raw", with: ""), withExtension: "raw") {
                fontURL = url
                break
            }
        }
        
        // If not found in bundle, try to find it in the current directory
        if fontURL == nil {
            let currentDir = FileManager.default.currentDirectoryPath
            for path in possiblePaths {
                let fullPath = "\(currentDir)/\(path)"
                if FileManager.default.fileExists(atPath: fullPath) {
                    fontURL = URL(fileURLWithPath: fullPath)
                    break
                }
            }
        }
        
        guard let url = fontURL else {
            print("Failed to find font file, using built-in font")
            // Create a built-in font as fallback
            createBuiltinFont()
            return
        }
        
        do {
            fontData = try Data(contentsOf: url)
            parseFontData()
            print("Font loaded successfully from: \(url.path)")
        } catch {
            print("Failed to load font: \(error), using built-in font")
            createBuiltinFont()
        }
    }
    
    private func createFallbackFont() {
        // Create a simple 8x16 bitmap font for fallback
        let charWidth = 8
        let charHeight = 16
        let numChars = 256
        
        for charIndex in 0..<numChars {
            var charBitmap: [Bool] = []
            
            // Create a simple pattern for each character
            for row in 0..<charHeight {
                for col in 0..<charWidth {
                    // Simple pattern: first and last rows, first and last columns
                    let isSet = row == 0 || row == charHeight - 1 || col == 0 || col == charWidth - 1
                    charBitmap.append(isSet)
                }
            }
            
            fontCache[UInt8(charIndex)] = charBitmap
        }
        
        print("Fallback font created successfully")
    }
    
    private func createBuiltinFont() {
        // Create a basic 8x16 font with common characters
        let charWidth = 8
        let charHeight = 16
        let numChars = 256
        
        // Define some basic character patterns
        let patterns: [UInt8: [UInt8]] = [
            0x20: [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00], // Space
            0x41: [0x00, 0x18, 0x24, 0x42, 0x42, 0x7E, 0x42, 0x42, 0x42, 0x42, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00], // A
            0x42: [0x00, 0x7C, 0x42, 0x42, 0x42, 0x7C, 0x42, 0x42, 0x42, 0x7C, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00], // B
            // Add more characters as needed
        ]
        
        for charIndex in 0..<numChars {
            if let pattern = patterns[UInt8(charIndex)] {
                var charBitmap: [Bool] = []
                for row in pattern {
                    for bit in 0..<charWidth {
                        let isSet = (row & (1 << (7 - bit))) != 0
                        charBitmap.append(isSet)
                    }
                }
                fontCache[UInt8(charIndex)] = charBitmap
            } else {
                // Create a simple fallback pattern
                var charBitmap: [Bool] = []
                for row in 0..<charHeight {
                    for col in 0..<charWidth {
                        let isSet = row == 0 || row == charHeight - 1 || col == 0 || col == charWidth - 1
                        charBitmap.append(isSet)
                    }
                }
                fontCache[UInt8(charIndex)] = charBitmap
            }
        }
        
        print("Built-in font created successfully")
    }
    
    private func parseFontData() {
        guard let data = fontData else { return }
        
        // PSF font format: 32-byte header + 256 characters * 16 bytes each
        let headerSize = 32
        let charHeight = 16
        let charWidth = 8
        let numChars = 256
        
        for charIndex in 0..<numChars {
            let charOffset = headerSize + (charIndex * charHeight)
            var charBitmap: [Bool] = []
            
            for row in 0..<charHeight {
                if charOffset + row < data.count {
                    let byte = data[charOffset + row]
                    for bit in 0..<charWidth {
                        let isSet = (byte & (1 << (7 - bit))) != 0
                        charBitmap.append(isSet)
                    }
                }
            }
            
            fontCache[UInt8(charIndex)] = charBitmap
        }
    }
    
    func getCharacterBitmap(for char: Character) -> [Bool]? {
        guard let scalar = char.unicodeScalars.first else {
            return fontCache[0x20] // Return space character
        }
        
        // CP866 encoding mapping for Russian characters
        let cp866Value = convertToCP866(scalar)
        return fontCache[cp866Value]
    }
    
    private func convertToCP866(_ unicodeScalar: UnicodeScalar) -> UInt8 {
        let value = unicodeScalar.value
        
        // Basic ASCII (0-127)
        if value <= 127 {
            return UInt8(value)
        }
        
        // CP866 to Unicode mapping (reverse of the one in TextDocument)
        let unicodeToCP866: [UInt32: UInt8] = [
            // Cyrillic symbols
            0x0410: 0x80, 0x0411: 0x81, 0x0412: 0x82, 0x0413: 0x83, 0x0414: 0x84, 0x0415: 0x85, 0x0416: 0x86, 0x0417: 0x87,
            0x0418: 0x88, 0x0419: 0x89, 0x041A: 0x8A, 0x041B: 0x8B, 0x041C: 0x8C, 0x041D: 0x8D, 0x041E: 0x8E, 0x041F: 0x8F,
            0x0420: 0x90, 0x0421: 0x91, 0x0422: 0x92, 0x0423: 0x93, 0x0424: 0x94, 0x0425: 0x95, 0x0426: 0x96, 0x0427: 0x97,
            0x0428: 0x98, 0x0429: 0x99, 0x042A: 0x9A, 0x042B: 0x9B, 0x042C: 0x9C, 0x042D: 0x9D, 0x042E: 0x9E, 0x042F: 0x9F,

        ]
        
        return unicodeToCP866[value] ?? 0x20 // Space for unknown characters
    }
    
    func createCustomFont() -> NSFont {
        // Create a custom font using the bitmap data
        // For now, we'll use a monospaced system font as fallback
        return NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
    }
}
