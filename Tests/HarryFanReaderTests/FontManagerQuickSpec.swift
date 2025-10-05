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
        specInitialState()
        specMSDOSFontEnum()
        specCharacterBitmaps()
        specCustomFontCreation()
        specFontSizeProperty()
        specAvailableFonts()
        specCP866Conversion()
    }

    // Tests for initial state: verifies default font, font size, and font list are valid and initialized as expected.
    private class func specInitialState() {
        var fontManager: FontManager!
        beforeEach { fontManager = FontManager() }
        afterEach { fontManager = nil }
        describe("FontManager") {
            context("initial state") {
                it("has a valid current font and font size") {
                    expect(fontManager.currentFont).toNot(beNil())
                    expect(fontManager.fontSize).to(equal(16.0))
                    expect(fontManager.availableFonts.count).to(beGreaterThan(0))
                }
                it("initializes with a valid font") {
                    expect(FontManager.MSDOSFont.allCases.contains(fontManager.currentFont)).to(beTrue())
                }
            }
        }
    }

    // Tests for MSDOSFont enum: ensures correct raw values, display names, and presence of all expected cases.
    private class func specMSDOSFontEnum() {
        describe("FontManager") {
            context("MSDOSFont enum") {
                it("has correct raw value and display name for vdu8x16") {
                    let vduFont = FontManager.MSDOSFont.vdu8x16
                    expect(vduFont.rawValue).to(equal("vdu.8x16"))
                    expect(vduFont.displayName).to(equal("vdu.8x16"))
                }
                it("contains all cases and specifically vdu8x16") {
                    let allFonts = FontManager.MSDOSFont.allCases
                    expect(allFonts.count).to(beGreaterThan(0))
                    expect(allFonts.contains(.vdu8x16)).to(beTrue())
                }
            }
        }
    }

    // Tests for character bitmap generation: covers ASCII, special, Unicode, empty, and consistency/difference cases.
    private class func specCharacterBitmaps() {
        var fontManager: FontManager!
        beforeEach { fontManager = FontManager() }
        afterEach { fontManager = nil }
        describe("FontManager") {
            context("getting character bitmaps") {
                it("returns non-nil bitmaps for basic ASCII characters") {
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
                it("returns non-nil bitmaps for special characters") {
                    let questionMarkBitmap = fontManager.getCharacterBitmap(for: "?")
                    expect(questionMarkBitmap).toNot(beNil())
                    expect(questionMarkBitmap?.count).to(equal(128))
                    let exclamationBitmap = fontManager.getCharacterBitmap(for: "!")
                    expect(exclamationBitmap).toNot(beNil())
                    expect(exclamationBitmap?.count).to(equal(128))
                }
                it("returns non-nil bitmap for Unicode character and falls back to '?'") {
                    let unicodeBitmap = fontManager.getCharacterBitmap(for: "€")
                    expect(unicodeBitmap).toNot(beNil())
                    expect(unicodeBitmap?.count).to(equal(128))
                }
                it("returns non-nil bitmap for empty character (fallback mechanism)") {
                    let emptyScalarBitmap = fontManager.getCharacterBitmap(for: Character(UnicodeScalar(0)!))
                    expect(emptyScalarBitmap).toNot(beNil())
                    expect(emptyScalarBitmap?.count).to(equal(128))
                }
                it("ensures consistency for the same character") {
                    let bitmap1 = fontManager.getCharacterBitmap(for: "A")
                    let bitmap2 = fontManager.getCharacterBitmap(for: "A")
                    expect(bitmap1).toNot(beNil())
                    expect(bitmap2).toNot(beNil())
                    expect(bitmap1).to(equal(bitmap2))
                }
                it("ensures differences for different characters") {
                    let aBitmap = fontManager.getCharacterBitmap(for: "A")
                    let bBitmap = fontManager.getCharacterBitmap(for: "B")
                    expect(aBitmap).toNot(beNil())
                    expect(bBitmap).toNot(beNil())
                    expect(aBitmap).toNot(equal(bBitmap))
                }
            }
        }
    }

    // Tests for custom font creation: verifies default and custom size, and monospaced property.
    private class func specCustomFontCreation() {
        var fontManager: FontManager!
        beforeEach { fontManager = FontManager() }
        afterEach { fontManager = nil }
        describe("FontManager") {
            context("creating custom fonts") {
                it("creates a custom font with default settings") {
                    let customFont = fontManager.createCustomFont()
                    expect(customFont).toNot(beNil())
                    if let customFont {
                        expect(customFont.pointSize).to(equal(fontManager.fontSize))
                        expect(customFont.isFixedPitch).to(beTrue())
                    }
                }
                it("creates a custom font with specified size") {
                    fontManager.fontSize = 20.0
                    let customFont = fontManager.createCustomFont()
                    expect(customFont).toNot(beNil())
                    if let customFont {
                        expect(customFont.pointSize).to(equal(20.0))
                    }
                }
            }
        }
    }

    // Tests for font size property: verifies default and updated values.
    private class func specFontSizeProperty() {
        var fontManager: FontManager!
        beforeEach { fontManager = FontManager() }
        afterEach { fontManager = nil }
        describe("FontManager") {
            context("font size property") {
                it("has a default size") {
                    expect(fontManager.fontSize).to(equal(16.0))
                }
                it("can be set to a new value") {
                    fontManager.fontSize = 12.0
                    expect(fontManager.fontSize).to(equal(12.0))
                    fontManager.fontSize = 24.0
                    expect(fontManager.fontSize).to(equal(24.0))
                }
            }
        }
    }

    // Tests for available fonts: ensures the list is not empty and all names are valid.
    private class func specAvailableFonts() {
        var fontManager: FontManager!
        beforeEach { fontManager = FontManager() }
        afterEach { fontManager = nil }
        describe("FontManager") {
            context("available fonts") {
                it("is not empty and contains valid font names") {
                    expect(fontManager.availableFonts.count).to(beGreaterThan(0))
                    expect(fontManager.availableFonts.isEmpty).to(beFalse())
                    for fontName in fontManager.availableFonts {
                        expect(fontName.isEmpty).to(beFalse())
                    }
                }
            }
        }
    }

    // Tests for CP866 conversion: covers ASCII and Cyrillic characters.
    private class func specCP866Conversion() {
        var fontManager: FontManager!
        beforeEach { fontManager = FontManager() }
        afterEach { fontManager = nil }
        describe("FontManager") {
            context("CP866 conversion") {
                it("handles ASCII characters correctly") {
                    let testChars: [Character] = ["A", "B", "0", "1", " ", "!", "@", "~"]
                    for char in testChars {
                        let bitmap = fontManager.getCharacterBitmap(for: char)
                        expect(bitmap).toNot(beNil(), description: "Failed to get bitmap for character: \(char)")
                        expect(bitmap?.count).to(equal(128), description: "Incorrect bitmap size for character: \(char)")
                    }
                }
                it("handles Cyrillic characters that are in CP866") {
                    let cyrillicChars: [Character] = ["А", "Б", "В", "а", "б", "в"]
                    for char in cyrillicChars {
                        let bitmap = fontManager.getCharacterBitmap(for: char)
                        expect(bitmap).toNot(beNil(), description: "Failed to get bitmap for Cyrillic character: \(char)")
                        expect(bitmap?.count).to(equal(128), description: "Incorrect bitmap size for Cyrillic character: \(char)")
                    }
                }
            }
        }
    }
}
