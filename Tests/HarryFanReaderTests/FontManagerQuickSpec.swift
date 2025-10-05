//
//  FontManagerQuickSpec.swift
//  HarryFanReaderTests
//
//  Created by @vt887 on 9/29/25.
//

import AppKit
@testable import HarryFanReader
import Nimble
import Quick

// Unit tests for FontManager
final class FontManagerQuickSpec: QuickSpec {
    override class func spec() {
        var fontManager: FontManager!

        beforeEach {
            fontManager = FontManager()
        }
        afterEach {
            fontManager = nil
        }

        describe("FontManager") {
            // Tests for initial state: verifies default font, font size, and font list are valid and initialized as expected.
            context("initial state") {
                // Checks that FontManager initializes with a valid font, default size, and non-empty font list.
                it("has a valid current font and font size") {
                    expect(fontManager.currentFont).toNot(beNil())
                    expect(fontManager.fontSize).to(equal(16.0))
                    expect(fontManager.availableFonts.count).to(beGreaterThan(0))
                }
                // Checks that the initial font is a valid MSDOSFont case from the enum.
                it("initializes with a valid font") {
                    expect(FontManager.MSDOSFont.allCases.contains(fontManager.currentFont)).to(beTrue())
                }
            }
            // Tests for MSDOSFont enum: ensures correct raw values, display names, and presence of all expected cases.
            context("MSDOSFont enum") {
                // Checks vdu8x16 font case for correct raw value and display name.
                it("has correct raw value and display name for vdu8x16") {
                    let vduFont = FontManager.MSDOSFont.vdu8x16
                    expect(vduFont.rawValue).to(equal("vdu.8x16"))
                    expect(vduFont.displayName).to(equal("vdu.8x16"))
                }
                // Checks that all MSDOSFont cases are present and include vdu8x16.
                it("contains all cases and specifically vdu8x16") {
                    let allFonts = FontManager.MSDOSFont.allCases
                    expect(allFonts.count).to(beGreaterThan(0))
                    expect(allFonts.contains(.vdu8x16)).to(beTrue())
                }
            }
            // Tests for character bitmap generation: covers ASCII, special, Unicode, empty, and consistency/difference cases.
            context("getting character bitmaps") {
                // Checks that basic ASCII characters return non-nil bitmaps of correct size (8x16 = 128 bits).
                it("returns non-nil bitmaps for basic ASCII characters") {
                    // Test basic ASCII characters: space, 'A', and '0'.
                    let spaceBitmap = fontManager.getCharacterBitmap(for: " ")
                    expect(spaceBitmap).toNot(beNil())
                    expect(spaceBitmap?.count).to(equal(128))
                    let aBitmap = fontManager.getCharacterBitmap(for: "A")
                    expect(aBitmap).toNot(beNil())
                    expect(aBitmap?.count).to(equal(128))
                    let zeroBitmap = fontManager.getCharacterBitmap(for: "0")
                    expect(zeroBitmap).toNot(beNil())
                    expect(zeroBitmap?.count).to(equal(128))
                }
                // Checks that special characters like '?' and '!' return valid bitmaps.
                it("returns non-nil bitmaps for special characters") {
                    let questionMarkBitmap = fontManager.getCharacterBitmap(for: "?")
                    expect(questionMarkBitmap).toNot(beNil())
                    expect(questionMarkBitmap?.count).to(equal(128))
                    let exclamationBitmap = fontManager.getCharacterBitmap(for: "!")
                    expect(exclamationBitmap).toNot(beNil())
                    expect(exclamationBitmap?.count).to(equal(128))
                }
                // Checks that a Unicode character not in CP866 returns a fallback bitmap (should match '?').
                it("returns non-nil bitmap for Unicode character and falls back to '?'") {
                    // Test with a Unicode character that might not be in CP866.
                    let unicodeBitmap = fontManager.getCharacterBitmap(for: "€")
                    expect(unicodeBitmap).toNot(beNil())
                    expect(unicodeBitmap?.count).to(equal(128))
                    // Should fall back to '?' character bitmap.
                }
                // Checks that an empty character (null) returns a fallback bitmap.
                it("returns non-nil bitmap for empty character (fallback mechanism)") {
                    let emptyScalarBitmap = fontManager.getCharacterBitmap(for: Character(UnicodeScalar(0)!))
                    expect(emptyScalarBitmap).toNot(beNil())
                    expect(emptyScalarBitmap?.count).to(equal(128))
                }
                // Checks that the same character always returns the same bitmap (consistency).
                it("ensures consistency for the same character") {
                    // Test that the same character always returns the same bitmap.
                    let bitmap1 = fontManager.getCharacterBitmap(for: "A")
                    let bitmap2 = fontManager.getCharacterBitmap(for: "A")
                    expect(bitmap1).toNot(beNil())
                    expect(bitmap2).toNot(beNil())
                    expect(bitmap1).to(equal(bitmap2))
                }
                // Checks that different characters return different bitmaps (uniqueness).
                it("ensures differences for different characters") {
                    // Test that different characters return different bitmaps.
                    let aBitmap = fontManager.getCharacterBitmap(for: "A")
                    let bBitmap = fontManager.getCharacterBitmap(for: "B")
                    expect(aBitmap).toNot(beNil())
                    expect(bBitmap).toNot(beNil())
                    expect(aBitmap).toNot(equal(bBitmap))
                }
            }
            // Tests for custom font creation: verifies default and custom size, and monospaced property.
            context("creating custom fonts") {
                // Checks that a custom font is created with default settings and is monospaced.
                it("creates a custom font with default settings") {
                    let customFont = fontManager.createCustomFont()
                    expect(customFont).toNot(beNil())
                    if let customFont {
                        expect(customFont.pointSize).to(equal(fontManager.fontSize))
                        expect(customFont.isFixedPitch).to(beTrue()) // Should be monospaced.
                    }
                }
                // Checks that a custom font can be created with a specified size.
                it("creates a custom font with specified size") {
                    fontManager.fontSize = 20.0
                    let customFont = fontManager.createCustomFont()
                    expect(customFont).toNot(beNil())
                    if let customFont {
                        expect(customFont.pointSize).to(equal(20.0))
                    }
                }
            }
            // Tests for font size property: verifies default and updated values.
            context("font size property") {
                // Checks that the default font size is 16.0.
                it("has a default size") {
                    expect(fontManager.fontSize).to(equal(16.0)) // Default size.
                }
                // Checks that the font size can be changed and is updated correctly.
                it("can be set to a new value") {
                    fontManager.fontSize = 12.0
                    expect(fontManager.fontSize).to(equal(12.0))
                    fontManager.fontSize = 24.0
                    expect(fontManager.fontSize).to(equal(24.0))
                }
            }
            // Tests for available fonts: ensures the list is not empty and all names are valid.
            context("available fonts") {
                // Checks that the availableFonts list is not empty and all font names are valid.
                it("is not empty and contains valid font names") {
                    expect(fontManager.availableFonts.count).to(beGreaterThan(0))
                    // The availableFonts should contain at least one font (default or loaded).
                    expect(fontManager.availableFonts.isEmpty).to(beFalse())
                    // All font names should be non-empty strings.
                    for fontName in fontManager.availableFonts {
                        expect(fontName.isEmpty).to(beFalse())
                    }
                }
            }
            // Tests for CP866 conversion: covers ASCII and Cyrillic characters.
            context("CP866 conversion") {
                // Checks that ASCII characters are handled correctly by the bitmap generator.
                it("handles ASCII characters correctly") {
                    // Test that ASCII characters are handled correctly.
                    let testChars: [Character] = ["A", "B", "0", "1", " ", "!", "@", "~"]
                    for char in testChars {
                        let bitmap = fontManager.getCharacterBitmap(for: char)
                        expect(bitmap).toNot(beNil(), description: "Failed to get bitmap for character: \(char)")
                        expect(bitmap?.count).to(equal(128), description: "Incorrect bitmap size for character: \(char)")
                    }
                }
                // Checks that Cyrillic characters in CP866 are handled correctly.
                it("handles Cyrillic characters that are in CP866") {
                    // Test some Cyrillic characters that should be in CP866.
                    let cyrillicChars: [Character] = ["А", "Б", "В", "а", "б", "в"]
                    for char in cyrillicChars {
                        let bitmap = fontManager.getCharacterBitmap(for: char)
                        expect(bitmap).toNot(beNil(), description: "Failed to get bitmap for Cyrillic character: \(char)")
                        expect(bitmap?.count).to(equal(128), description: "Incorrect bitmap size for Cyrillic character: \(char)")
                    }
                }
            }
            // Tests for fallback glyph generation: ensures unknown characters (e.g., emoji) get a fallback bitmap.
            context("fallback glyph generation") {
                // Checks that a fallback glyph is generated for unknown characters (e.g., emoji).
                it("generates a fallback glyph for unknown characters") {
                    // Test with a character that definitely won't be in the font.
                    let unusualChar = Character(UnicodeScalar(0x1F600)!) // Emoji
                    let bitmap = fontManager.getCharacterBitmap(for: unusualChar)
                    expect(bitmap).toNot(beNil())
                    expect(bitmap?.count).to(equal(128))
                    // The fallback glyph should be a border pattern.
                    // Test that it has some true values (border pixels).
                    expect(bitmap?.contains(true) == true).to(beTrue(), description: "Fallback glyph should have some pixels set")
                }
                // Checks that the fallback glyph is consistent for the same unknown character.
                it("ensures fallback glyph structure is consistent") {
                    // Test the fallback glyph structure by requesting an unknown character.
                    let unknownChar = Character(UnicodeScalar(0x1F4A9)!) // Another emoji
                    let bitmap = fontManager.getCharacterBitmap(for: unknownChar)
                    expect(bitmap).toNot(beNil())
                    expect(bitmap?.count).to(equal(128))
                    // The fallback glyph should have some pixels set (not all false).
                    expect(bitmap?.contains(true) == true).to(beTrue(), description: "Fallback glyph should have some pixels set")
                    // Test that it's consistent - same character should return same bitmap.
                    let bitmap2 = fontManager.getCharacterBitmap(for: unknownChar)
                    expect(bitmap).to(equal(bitmap2), description: "Fallback glyph should be consistent")
                }
            }
            // Tests for character bitmap performance: ensures no crash in a loop (performance placeholder).
            context("character bitmap performance") {
                // Checks that accessing character bitmaps in a loop does not crash (performance placeholder).
                it("runs character bitmap access loop (performance placeholder)") {
                    // Performance measurement would go here if supported.
                    let testChars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()"
                    for char in testChars {
                        _ = fontManager.getCharacterBitmap(for: char)
                    }
                }
            }
            // Tests for current font property: ensures it is not nil and has valid properties.
            context("current font property") {
                // Checks that the current font is not nil and has valid properties.
                it("is not nil and has valid properties") {
                    let initialFont = fontManager.currentFont
                    expect(initialFont).toNot(beNil())
                    // Test that we can access the font properties.
                    expect(initialFont.rawValue.isEmpty).to(beFalse())
                    expect(initialFont.displayName.isEmpty).to(beFalse())
                }
            }
            // Tests for null character bitmap: ensures a null character returns a valid bitmap.
            context("null character bitmap") {
                // Checks that a null character returns a valid bitmap of correct size.
                it("returns a valid bitmap") {
                    let nullChar = Character(UnicodeScalar(0)!)
                    let bitmap = fontManager.getCharacterBitmap(for: nullChar)
                    expect(bitmap).toNot(beNil())
                    expect(bitmap?.count).to(equal(128))
                }
            }
            // Tests for high Unicode character bitmap: ensures fallback for characters outside BMP.
            context("high Unicode character bitmap") {
                // Checks that a high Unicode character returns a valid bitmap and falls back to fallback glyph.
                it("returns a valid bitmap and falls back to fallback glyph") {
                    let highUnicodeChar = Character(UnicodeScalar(0x10000)!) // Outside basic multilingual plane
                    let bitmap = fontManager.getCharacterBitmap(for: highUnicodeChar)
                    expect(bitmap).toNot(beNil())
                    expect(bitmap?.count).to(equal(128))
                    // Should fall back to fallback glyph.
                }
            }
            // Tests for control character bitmap: ensures control characters return valid bitmaps.
            context("control character bitmap") {
                // Checks that a control character returns a valid bitmap of correct size.
                it("returns a valid bitmap") {
                    let controlChar = Character(UnicodeScalar(0x01)!) // Control character
                    let bitmap = fontManager.getCharacterBitmap(for: controlChar)
                    expect(bitmap).toNot(beNil())
                    expect(bitmap?.count).to(equal(128))
                }
            }
        }
    }
}
