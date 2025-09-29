//
//  UtilityTests.swift
//  HarryFanReaderTests
//
//  Created by Tests on 9/29/25.
//

import XCTest
@testable import HarryFan_Reader

final class UtilityTests: XCTestCase {
    
    // MARK: - SearchDirection Enum Tests
    
    func testSearchDirectionEnum() {
        XCTAssertEqual(SearchDirection.forward, SearchDirection.forward)
        XCTAssertEqual(SearchDirection.backward, SearchDirection.backward)
        XCTAssertNotEqual(SearchDirection.forward, SearchDirection.backward)
    }
    
    // MARK: - AppSettings Tests
    
    func testAppSettingsConstants() {
        XCTAssertEqual(AppSettings.appName, "HarryFan Reader")
        XCTAssertEqual(AppSettings.homeDir, "~/.harryfan")
        XCTAssertEqual(AppSettings.fontFileName, "ddd.8x16")
        XCTAssertEqual(AppSettings.defaultFontFileName, "vdu.8x16")
        XCTAssertEqual(AppSettings.appearance, .blue)
        XCTAssertEqual(AppSettings.numScreenRows, 24)
        XCTAssertEqual(AppSettings.cols, 80)
        XCTAssertEqual(AppSettings.rows, 24)
        XCTAssertEqual(AppSettings.charW, 8)
        XCTAssertEqual(AppSettings.charH, 16)
        XCTAssertEqual(AppSettings.wrapWidth, 80)
        XCTAssertEqual(AppSettings.wordWrap, true)
        XCTAssertEqual(AppSettings.shouldShowQuitMessage, false)
        XCTAssertEqual(AppSettings.debug, false)
    }
    
    func testAppSettingsDimensions() {
        // Test that character dimensions make sense for a typical font
        XCTAssertGreaterThan(AppSettings.charW, 0)
        XCTAssertGreaterThan(AppSettings.charH, 0)
        XCTAssertGreaterThan(AppSettings.cols, 0)
        XCTAssertGreaterThan(AppSettings.rows, 0)
        XCTAssertGreaterThan(AppSettings.wrapWidth, 0)
    }
    
    // MARK: - AppAppearance Enum Tests
    
    func testAppAppearanceEnum() {
        let allCases = AppAppearance.allCases
        XCTAssertTrue(allCases.contains(.light))
        XCTAssertTrue(allCases.contains(.dark))
        XCTAssertTrue(allCases.contains(.blue))
        XCTAssertEqual(allCases.count, 3)
    }
    
    func testAppAppearanceRawValues() {
        XCTAssertEqual(AppAppearance.light.rawValue, "light")
        XCTAssertEqual(AppAppearance.dark.rawValue, "dark")
        XCTAssertEqual(AppAppearance.blue.rawValue, "blue")
    }
    
    func testAppAppearanceInitFromRawValue() {
        XCTAssertEqual(AppAppearance(rawValue: "light"), .light)
        XCTAssertEqual(AppAppearance(rawValue: "dark"), .dark)
        XCTAssertEqual(AppAppearance(rawValue: "blue"), .blue)
        XCTAssertNil(AppAppearance(rawValue: "invalid"))
    }
    
    // MARK: - Messages Tests
    
    func testWelcomeMessage() {
        let welcomeMessage = Messages.welcomeMessage
        XCTAssertFalse(welcomeMessage.isEmpty)
        XCTAssertTrue(welcomeMessage.contains("HarryFan Reader"))
        XCTAssertTrue(welcomeMessage.contains("╔"))
        XCTAssertTrue(welcomeMessage.contains("╗"))
        XCTAssertTrue(welcomeMessage.contains("╚"))
        XCTAssertTrue(welcomeMessage.contains("╝"))
    }
    
    func testHelloMessage() {
        let helloMessage = Messages.helloMessage
        XCTAssertFalse(helloMessage.isEmpty)
        XCTAssertTrue(helloMessage.contains("Welcome"))
        XCTAssertTrue(helloMessage.contains("retro"))
        XCTAssertTrue(helloMessage.contains("MS-DOS"))
        XCTAssertTrue(helloMessage.contains("F1"))
        XCTAssertTrue(helloMessage.contains("F10"))
        XCTAssertTrue(helloMessage.contains("Help"))
        XCTAssertTrue(helloMessage.contains("Quit"))
    }
    
    func testQuitMessage() {
        let quitMessage = Messages.quitMessage
        XCTAssertFalse(quitMessage.isEmpty)
        XCTAssertTrue(quitMessage.contains("Thank you"))
        XCTAssertTrue(quitMessage.contains("HarryFan Reader"))
        XCTAssertTrue(quitMessage.contains("Y/N"))
        XCTAssertTrue(quitMessage.contains("╔"))
        XCTAssertTrue(quitMessage.contains("╗"))
        XCTAssertTrue(quitMessage.contains("╚"))
        XCTAssertTrue(quitMessage.contains("╝"))
    }
    
    func testMessageBoxFormatting() {
        // Test that messages have proper box drawing characters
        let messages = [Messages.welcomeMessage, Messages.helloMessage, Messages.quitMessage]
        
        for message in messages {
            XCTAssertTrue(message.contains("╔"), "Message should have top-left corner")
            XCTAssertTrue(message.contains("╗"), "Message should have top-right corner")
            XCTAssertTrue(message.contains("╚"), "Message should have bottom-left corner")
            XCTAssertTrue(message.contains("╝"), "Message should have bottom-right corner")
            XCTAssertTrue(message.contains("║"), "Message should have vertical borders")
        }
    }
    
    // MARK: - Unicode Points Tests
    
    func testUnicodePointsArray() {
        XCTAssertEqual(unicodePoints.count, 256) // CP866 has 256 code points
        
        // Test some known mappings
        XCTAssertEqual(unicodePoints[0x20], 0x0020) // Space character
        XCTAssertEqual(unicodePoints[0x41], 0x0041) // 'A' character
        XCTAssertEqual(unicodePoints[0x61], 0x0061) // 'a' character
        XCTAssertEqual(unicodePoints[0x30], 0x0030) // '0' character
    }
    
    func testUnicodePointsASCIIRange() {
        // Test that ASCII range (0-127) maps correctly
        for i in 0...127 {
            XCTAssertEqual(unicodePoints[i], UInt32(i), "ASCII character \(i) should map to itself")
        }
    }
    
    func testUnicodePointsCyrillicRange() {
        // Test some Cyrillic characters that should be present in CP866
        // А (capital A cyrillic) should be at position 128 (0x80)
        XCTAssertEqual(unicodePoints[0x80], 0x0410) // А
        XCTAssertEqual(unicodePoints[0x81], 0x0411) // Б
        XCTAssertEqual(unicodePoints[0x82], 0x0412) // В
        
        // а (lowercase a cyrillic) should be at position 160 (0xA0)
        XCTAssertEqual(unicodePoints[0xA0], 0x0430) // а
        XCTAssertEqual(unicodePoints[0xA1], 0x0431) // б
        XCTAssertEqual(unicodePoints[0xA2], 0x0432) // в
    }
    
    func testUnicodePointsBoxDrawingCharacters() {
        // Test some box drawing characters used in the interface
        // These should be in the 176-223 range (0xB0-0xDF)
        XCTAssertEqual(unicodePoints[0xB0], 0x2591) // Light shade
        XCTAssertEqual(unicodePoints[0xB1], 0x2592) // Medium shade
        XCTAssertEqual(unicodePoints[0xB2], 0x2593) // Dark shade
        XCTAssertEqual(unicodePoints[0xB3], 0x2502) // Box drawings light vertical
    }
    
    func testUnicodePointsSpecialCharacters() {
        // Test some special characters
        XCTAssertEqual(unicodePoints[0xF0], 0x0401) // Ё
        XCTAssertEqual(unicodePoints[0xF1], 0x0451) // ё
        XCTAssertEqual(unicodePoints[0xF8], 0x00B0) // Degree symbol
        XCTAssertEqual(unicodePoints[0xFF], 0x00A0) // Non-breaking space
    }
    
    // MARK: - DebugLogger Tests
    
    func testDebugLoggerWhenDebugDisabled() {
        // Since debug is false by default, logging should be silent
        // We can't easily test console output, but we can test that the methods don't crash
        DebugLogger.log("Test log message")
        DebugLogger.logError("Test error message")
        DebugLogger.logWarning("Test warning message")
        
        // If we get here without crashing, the test passes
        XCTAssertTrue(true)
    }
    
    // MARK: - Integration Tests
    
    func testAppSettingsAndUnicodePointsConsistency() {
        // Test that character dimensions are consistent with font expectations
        let expectedBitmapSize = AppSettings.charW * AppSettings.charH
        XCTAssertEqual(expectedBitmapSize, 128) // 8 * 16 = 128 bits per character
    }
    
    func testMessageFormattingWithAppSettings() {
        // Test that messages fit within the expected column width
        let lines = Messages.helloMessage.components(separatedBy: .newlines)
        
        for line in lines {
            // Remove box drawing characters for content length check
            let contentLine = line.replacingOccurrences(of: "║", with: "").trimmingCharacters(in: .whitespaces)
            if !contentLine.isEmpty {
                // Content should fit within reasonable bounds (allowing for some flexibility)
                XCTAssertLessThanOrEqual(contentLine.count, AppSettings.cols + 10, "Line too long: \(line)")
            }
        }
    }
    
    // MARK: - Edge Cases and Error Handling
    
    func testUnicodePointsBoundaryValues() {
        // Test boundary values
        XCTAssertGreaterThanOrEqual(unicodePoints[0], 0)
        XCTAssertGreaterThanOrEqual(unicodePoints[255], 0)
        
        // All values should be valid Unicode scalar values
        for point in unicodePoints {
            XCTAssertNotNil(UnicodeScalar(point), "Invalid Unicode scalar: \(point)")
        }
    }
    
    func testEmptyStringHandling() {
        // Test that empty strings are handled gracefully in messages
        XCTAssertFalse(Messages.welcomeMessage.isEmpty)
        XCTAssertFalse(Messages.helloMessage.isEmpty)
        XCTAssertFalse(Messages.quitMessage.isEmpty)
    }
    
    // MARK: - Performance Tests
    
    func testUnicodePointsAccessPerformance() {
        measure {
            for i in 0..<1000 {
                let index = i % 256
                _ = unicodePoints[index]
            }
        }
    }
    
    func testMessageAccessPerformance() {
        measure {
            for _ in 0..<100 {
                _ = Messages.welcomeMessage
                _ = Messages.helloMessage
                _ = Messages.quitMessage
            }
        }
    }
}
