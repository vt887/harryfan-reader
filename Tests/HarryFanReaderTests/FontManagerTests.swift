//
//  FontManagerTests.swift
//  HarryFanReaderTests
//
//  Created by @vt887 on 9/29/25.
//

import AppKit
@testable import HarryFan_Reader
import XCTest

final class FontManagerTests: XCTestCase {
    var fontManager: FontManager!

    override func setUp() {
        super.setUp()
        fontManager = FontManager()
    }

    override func tearDown() {
        fontManager = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialState() {
        XCTAssertNotNil(fontManager.currentFont)
        XCTAssertEqual(fontManager.fontSize, 16.0)
        XCTAssertGreaterThan(fontManager.availableFonts.count, 0)
    }

    func testInitialFontSelection() {
        // FontManager should initialize with a valid font
        XCTAssertTrue(FontManager.MSDOSFont.allCases.contains(fontManager.currentFont))
    }

    // MARK: - Font Enum Tests

    func testMSDOSFontEnum() {
        let vduFont = FontManager.MSDOSFont.vdu8x16
        XCTAssertEqual(vduFont.rawValue, "vdu.8x16")
        XCTAssertEqual(vduFont.displayName, "vdu.8x16")
    }

    func testAllMSDOSFonts() {
        let allFonts = FontManager.MSDOSFont.allCases
        XCTAssertGreaterThan(allFonts.count, 0)
        XCTAssertTrue(allFonts.contains(.vdu8x16))
    }

    // MARK: - Character Bitmap Tests

    func testGetCharacterBitmapForBasicASCII() {
        // Test basic ASCII characters
        let spaceBitmap = fontManager.getCharacterBitmap(for: " ")
        XCTAssertNotNil(spaceBitmap)
        XCTAssertEqual(spaceBitmap?.count, 128) // 8x16 = 128 bits

        let aBitmap = fontManager.getCharacterBitmap(for: "A")
        XCTAssertNotNil(aBitmap)
        XCTAssertEqual(aBitmap?.count, 128)

        let zeroBitmap = fontManager.getCharacterBitmap(for: "0")
        XCTAssertNotNil(zeroBitmap)
        XCTAssertEqual(zeroBitmap?.count, 128)
    }

    func testGetCharacterBitmapForSpecialCharacters() {
        let questionMarkBitmap = fontManager.getCharacterBitmap(for: "?")
        XCTAssertNotNil(questionMarkBitmap)
        XCTAssertEqual(questionMarkBitmap?.count, 128)

        let exclamationBitmap = fontManager.getCharacterBitmap(for: "!")
        XCTAssertNotNil(exclamationBitmap)
        XCTAssertEqual(exclamationBitmap?.count, 128)
    }

    func testGetCharacterBitmapForUnicodeCharacter() {
        // Test with a Unicode character that might not be in CP866
        let unicodeBitmap = fontManager.getCharacterBitmap(for: "€")
        XCTAssertNotNil(unicodeBitmap)
        XCTAssertEqual(unicodeBitmap?.count, 128)
        // Should fall back to '?' character bitmap
    }

    func testGetCharacterBitmapForEmptyCharacter() {
        // This tests the fallback mechanism
        let emptyScalarBitmap = fontManager.getCharacterBitmap(for: Character(UnicodeScalar(0)!))
        XCTAssertNotNil(emptyScalarBitmap)
        XCTAssertEqual(emptyScalarBitmap?.count, 128)
    }

    func testBitmapConsistency() {
        // Test that the same character always returns the same bitmap
        let bitmap1 = fontManager.getCharacterBitmap(for: "A")
        let bitmap2 = fontManager.getCharacterBitmap(for: "A")

        XCTAssertNotNil(bitmap1)
        XCTAssertNotNil(bitmap2)
        XCTAssertEqual(bitmap1, bitmap2)
    }

    func testBitmapDifferences() {
        // Test that different characters return different bitmaps
        let aBitmap = fontManager.getCharacterBitmap(for: "A")
        let bBitmap = fontManager.getCharacterBitmap(for: "B")

        XCTAssertNotNil(aBitmap)
        XCTAssertNotNil(bBitmap)
        XCTAssertNotEqual(aBitmap, bBitmap)
    }

    // MARK: - System Font Tests

    func testCreateCustomFont() {
        let customFont = fontManager.createCustomFont()

        XCTAssertNotNil(customFont)
        XCTAssertEqual(customFont.pointSize, fontManager.fontSize)
        XCTAssertTrue(customFont.isFixedPitch) // Should be monospaced
    }

    func testCreateCustomFontWithDifferentSize() {
        fontManager.fontSize = 20.0
        let customFont = fontManager.createCustomFont()

        XCTAssertNotNil(customFont)
        XCTAssertEqual(customFont.pointSize, 20.0)
    }

    // MARK: - Font Size Tests

    func testFontSizeProperty() {
        XCTAssertEqual(fontManager.fontSize, 16.0) // Default size

        fontManager.fontSize = 12.0
        XCTAssertEqual(fontManager.fontSize, 12.0)

        fontManager.fontSize = 24.0
        XCTAssertEqual(fontManager.fontSize, 24.0)
    }

    // MARK: - Available Fonts Tests

    func testAvailableFonts() {
        XCTAssertGreaterThan(fontManager.availableFonts.count, 0)
        // The availableFonts should contain at least one font
        // In test environment, it might just be the default font
        XCTAssertFalse(fontManager.availableFonts.isEmpty)

        // All font names should be non-empty
        for fontName in fontManager.availableFonts {
            XCTAssertFalse(fontName.isEmpty)
        }
    }

    // MARK: - CP866 Conversion Tests

    func testCP866ConversionForASCII() {
        // Test that ASCII characters are handled correctly
        let testChars: [Character] = ["A", "B", "0", "1", " ", "!", "@", "~"]

        for char in testChars {
            let bitmap = fontManager.getCharacterBitmap(for: char)
            XCTAssertNotNil(bitmap, "Failed to get bitmap for character: \(char)")
            XCTAssertEqual(bitmap?.count, 128, "Incorrect bitmap size for character: \(char)")
        }
    }

    func testCP866ConversionForCyrillicCharacters() {
        // Test some Cyrillic characters that should be in CP866
        let cyrillicChars: [Character] = ["А", "Б", "В", "а", "б", "в"]

        for char in cyrillicChars {
            let bitmap = fontManager.getCharacterBitmap(for: char)
            XCTAssertNotNil(bitmap, "Failed to get bitmap for Cyrillic character: \(char)")
            XCTAssertEqual(bitmap?.count, 128, "Incorrect bitmap size for Cyrillic character: \(char)")
        }
    }

    // MARK: - Fallback Glyph Tests

    func testFallbackGlyphGeneration() {
        // Test with a character that definitely won't be in the font
        let unusualChar = Character(UnicodeScalar(0x1F600)!) // Emoji
        let bitmap = fontManager.getCharacterBitmap(for: unusualChar)

        XCTAssertNotNil(bitmap)
        XCTAssertEqual(bitmap?.count, 128)

        // The fallback glyph should be a border pattern
        // Test that it has some true values (border pixels)
        XCTAssertTrue(bitmap?.contains(true) == true, "Fallback glyph should have some pixels set")
    }

    func testFallbackGlyphStructure() {
        // Test the fallback glyph structure by requesting an unknown character
        let unknownChar = Character(UnicodeScalar(0x1F4A9)!) // Another emoji
        let bitmap = fontManager.getCharacterBitmap(for: unknownChar)

        XCTAssertNotNil(bitmap)
        XCTAssertEqual(bitmap?.count, 128)

        // The fallback glyph should have some pixels set (not all false)
        XCTAssertTrue(bitmap?.contains(true) == true, "Fallback glyph should have some pixels set")

        // Test that it's consistent - same character should return same bitmap
        let bitmap2 = fontManager.getCharacterBitmap(for: unknownChar)
        XCTAssertEqual(bitmap, bitmap2, "Fallback glyph should be consistent")
    }

    // MARK: - Performance Tests

    func testCharacterBitmapPerformance() {
        // Test that getting character bitmaps is reasonably fast
        let testChars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()"

        measure {
            for char in testChars {
                _ = fontManager.getCharacterBitmap(for: char)
            }
        }
    }

    // MARK: - Font Loading Tests

    func testCurrentFontProperty() {
        let initialFont = fontManager.currentFont
        XCTAssertNotNil(initialFont)

        // Test that we can access the font properties
        XCTAssertFalse(initialFont.rawValue.isEmpty)
        XCTAssertFalse(initialFont.displayName.isEmpty)
    }

    // MARK: - Edge Cases

    func testNullCharacterBitmap() {
        let nullChar = Character(UnicodeScalar(0)!)
        let bitmap = fontManager.getCharacterBitmap(for: nullChar)

        XCTAssertNotNil(bitmap)
        XCTAssertEqual(bitmap?.count, 128)
    }

    func testHighUnicodeCharacterBitmap() {
        let highUnicodeChar = Character(UnicodeScalar(0x10000)!) // Outside basic multilingual plane
        let bitmap = fontManager.getCharacterBitmap(for: highUnicodeChar)

        XCTAssertNotNil(bitmap)
        XCTAssertEqual(bitmap?.count, 128)
        // Should fall back to fallback glyph
    }

    func testControlCharacterBitmap() {
        let controlChar = Character(UnicodeScalar(0x01)!) // Control character
        let bitmap = fontManager.getCharacterBitmap(for: controlChar)

        XCTAssertNotNil(bitmap)
        XCTAssertEqual(bitmap?.count, 128)
    }
}
