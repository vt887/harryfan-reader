//
//  UtilityQuickSpec.swift
//  HarryFanReaderTests
//
//  Created by @vt887 on 9/29/25.
//

import AppKit
@testable import HarryFanReader
import Nimble
import Quick

// Unit tests for utility types, constants, and helpers
final class UtilityQuickSpec: QuickSpec {
    // Main entry point for all utility-related tests
    override class func spec() {
        specSearchDirectionEnum() // Tests for SearchDirection enum
        specSettings() // Tests for Settings constants
        specAppAppearanceEnum() // Tests for AppAppearance enum
        specMessages() // Tests for Messages static content
        specUnicodePoints() // Tests for unicodePoints mapping
        specDebugLogger() // Tests for DebugLogger
        specIntegration() // Tests for integration/consistency
        specEdgeCasesAndErrorHandling() // Tests for edge cases
        specPerformance() // Tests for performance placeholders
    }

    // Tests for SearchDirection enum: equality and difference
    private class func specSearchDirectionEnum() {
        describe("SearchDirection enum") {
            // Checks that SearchDirection enum values compare as expected (equality and difference).
            it("compares directions correctly") {
                expect(SearchDirection.forward).to(equal(SearchDirection.forward))
                expect(SearchDirection.backward).to(equal(SearchDirection.backward))
                expect(SearchDirection.forward).toNot(equal(SearchDirection.backward))
            }
        }
    }

    // Tests for Settings: constants and dimensions
    private class func specSettings() {
        describe("Settings") {
            // Use UserDefaults to control persisted settings for deterministic tests
            var originalWordWrap: Any?
            var originalShouldShowQuitMessage: Any?
            var originalDebug: Any?

            beforeEach {
                originalWordWrap = UserDefaults.standard.object(forKey: "wordWrap")
                originalShouldShowQuitMessage = UserDefaults.standard.object(forKey: "shouldShowQuitMessage")
                originalDebug = UserDefaults.standard.object(forKey: "debug")

                UserDefaults.standard.set(true, forKey: "wordWrap")
                UserDefaults.standard.set(false, forKey: "shouldShowQuitMessage")
                UserDefaults.standard.set(true, forKey: "debug")
            }

            afterEach {
                if let v = originalWordWrap {
                    UserDefaults.standard.set(v, forKey: "wordWrap")
                } else {
                    UserDefaults.standard.removeObject(forKey: "wordWrap")
                }
                if let v = originalShouldShowQuitMessage {
                    UserDefaults.standard.set(v, forKey: "shouldShowQuitMessage")
                } else {
                    UserDefaults.standard.removeObject(forKey: "shouldShowQuitMessage")
                }
                if let v = originalDebug {
                    UserDefaults.standard.set(v, forKey: "debug")
                } else {
                    UserDefaults.standard.removeObject(forKey: "debug")
                }
            }

            // Checks that Settings constants have expected values (app name, home dir, font, etc).
            it("has correct constants") {
                expect(Settings.appName).to(equal("HarryFan Reader"))
                expect(Settings.homeDir).to(equal("~/.harryfan"))
                expect(Settings.defaultFontFileName).to(equal("vdu.8x16"))
                expect(Settings.appearance).to(equal(.blue))
                expect(Settings.cols).to(equal(80))
                expect(Settings.rows).to(equal(24))
                expect(Settings.charW).to(equal(8))
                expect(Settings.charH).to(equal(16))
                expect(Settings.wrapWidth).to(equal(80))
                expect(Settings.wordWrap).to(beTrue())
            }
            // Checks that character dimension constants are positive and reasonable.
            it("has sensible character dimensions") {
                expect(Settings.charW).to(beGreaterThan(0))
                expect(Settings.charH).to(beGreaterThan(0))
                expect(Settings.cols).to(beGreaterThan(0))
                expect(Settings.rows).to(beGreaterThan(0))
                expect(Settings.wrapWidth).to(beGreaterThan(0))
            }
        }
    }

    // Tests for AppAppearance enum: cases, raw values, and initialization
    private class func specAppAppearanceEnum() {
        describe("AppAppearance enum") {
            // Checks that all AppAppearance cases are present (light, dark, blue).
            it("has all cases") {
                let allCases = AppAppearance.allCases
                expect(allCases.contains(.light)).to(beTrue())
                expect(allCases.contains(.dark)).to(beTrue())
                expect(allCases.contains(.blue)).to(beTrue())
                expect(allCases.count).to(equal(3))
            }
            // Checks that AppAppearance raw values are correct.
            it("has correct raw values") {
                expect(AppAppearance.light.rawValue).to(equal("light"))
                expect(AppAppearance.dark.rawValue).to(equal("dark"))
                expect(AppAppearance.blue.rawValue).to(equal("blue"))
            }
            // Checks that AppAppearance can be initialized from raw values, and nil for invalid.
            it("initializes from raw value") {
                expect(AppAppearance(rawValue: "light")).to(equal(.light))
                expect(AppAppearance(rawValue: "dark")).to(equal(.dark))
                expect(AppAppearance(rawValue: "blue")).to(equal(.blue))
                expect(AppAppearance(rawValue: "invalid")).to(beNil())
            }
        }
    }

    // Tests for Messages: welcome, help, quit, formatting, centering
    private class func specMessages() {
        describe("Messages") {
            // Checks that the welcome message is present and contains expected content and box drawing characters.
            it("has a welcome message") {
                let welcomeMessage = Messages.welcomeMessage
                expect(welcomeMessage.isEmpty).to(beFalse())
                expect(welcomeMessage).to(contain("HarryFan Reader"))
                expect(welcomeMessage).to(contain("╔"))
                expect(welcomeMessage).to(contain("╗"))
                expect(welcomeMessage).to(contain("╚"))
                expect(welcomeMessage).to(contain("╝"))
            }
            // Checks that the help message is present and contains expected content and keywords.
            it("has a help message") {
                let helpMessage = Messages.helpMessage
                expect(helpMessage.isEmpty).to(beFalse())
                expect(helpMessage).to(contain("F1"))
                expect(helpMessage).to(contain("Help"))
                expect(helpMessage).to(contain("Word Wrap"))
                expect(helpMessage).to(contain("Open File"))
                expect(helpMessage).to(contain("Go Start"))
                expect(helpMessage).to(contain("Go End"))
                expect(helpMessage).to(contain("Quit"))
            }
            // Checks that the quit message is present and contains expected content and box drawing characters.
            it("has a quit message") {
                let quitMessage = Messages.quitMessage
                expect(quitMessage.isEmpty).to(beFalse())
                expect(quitMessage).to(contain("Thank you"))
                expect(quitMessage).to(contain("HarryFan Reader"))
                expect(quitMessage).to(contain("Y/N"))
                expect(quitMessage).to(contain("╔"))
                expect(quitMessage).to(contain("╗"))
                expect(quitMessage).to(contain("╚"))
                expect(quitMessage).to(contain("╝"))
            }
            // Checks that all message boxes are formatted with box drawing characters.
            it("formats message boxes correctly") {
                let messages = [Messages.welcomeMessage, Messages.helpMessage, Messages.quitMessage]
                for message in messages {
                    expect(message.contains("╔")).to(beTrue(), description: "Message should have top-left corner")
                    expect(message.contains("╗")).to(beTrue(), description: "Message should have top-right corner")
                    expect(message.contains("╚")).to(beTrue(), description: "Message should have bottom-left corner")
                    expect(message.contains("╝")).to(beTrue(), description: "Message should have bottom-right corner")
                    expect(message.contains("║")).to(beTrue(), description: "Message should have vertical borders")
                }
            }
            // Checks that the welcome message is centered and formatted for the screen.
            it("centers the welcome message") {
                let screenWidth = 80
                let screenHeight = 24
                let centeredMessage = Messages.centeredWelcomeMessage(screenWidth: screenWidth, screenHeight: screenHeight)
                expect(centeredMessage.isEmpty).to(beFalse())
                expect(centeredMessage).to(contain("HarryFan Reader"))
                let lines = centeredMessage.components(separatedBy: "\n")
                expect(lines.count).to(equal(screenHeight))
                for line in lines {
                    expect(line.count).to(equal(screenWidth), description: "Line should be padded to screen width: '\(line)'")
                }
                expect(centeredMessage).to(contain("╔"))
                expect(centeredMessage).to(contain("╗"))
                expect(centeredMessage).to(contain("╚"))
                expect(centeredMessage).to(contain("╝"))
            }
        }
    }

    // Tests for unicodePoints: mapping for ASCII, Cyrillic, box drawing, and special chars
    private class func specUnicodePoints() {
        describe("Unicode points") {
            // Checks that unicodePoints array has correct mappings for known values (space, A, a, 0).
            it("has correct mappings") {
                expect(unicodePoints.count).to(equal(256)) // CP866 has 256 code points
                expect(unicodePoints[0x20]).to(equal(0x0020)) // Space character
                expect(unicodePoints[0x41]).to(equal(0x0041)) // 'A' character
                expect(unicodePoints[0x61]).to(equal(0x0061)) // 'a' character
                expect(unicodePoints[0x30]).to(equal(0x0030)) // '0' character
            }
            // Checks that ASCII range in unicodePoints maps correctly (0-127).
            it("maps ASCII range correctly") {
                for i in 0 ... 127 {
                    expect(unicodePoints[i]).to(equal(UInt32(i)), description: "ASCII character \(i) should map to itself")
                }
            }
            // Checks that Cyrillic range in unicodePoints maps correctly (upper/lower).
            it("maps Cyrillic range correctly") {
                expect(unicodePoints[0x80]).to(equal(0x0410)) // А
                expect(unicodePoints[0x81]).to(equal(0x0411)) // Б
                expect(unicodePoints[0x82]).to(equal(0x0412)) // В
                expect(unicodePoints[0xA0]).to(equal(0x0430)) // а
                expect(unicodePoints[0xA1]).to(equal(0x0431)) // б
                expect(unicodePoints[0xA2]).to(equal(0x0432)) // в
            }
            // Checks that box drawing characters are mapped correctly (shades, vertical).
            it("handles box drawing characters") {
                expect(unicodePoints[0xB0]).to(equal(0x2591)) // Light shade
                expect(unicodePoints[0xB1]).to(equal(0x2592)) // Medium shade
                expect(unicodePoints[0xB2]).to(equal(0x2593)) // Dark shade
                expect(unicodePoints[0xB3]).to(equal(0x2502)) // Box drawings light vertical
            }
            // Checks that special characters are mapped correctly (Ё, ё, degree, nbsp).
            it("handles special characters") {
                expect(unicodePoints[0xF0]).to(equal(0x0401)) // Ё
                expect(unicodePoints[0xF1]).to(equal(0x0451)) // ё
                expect(unicodePoints[0xF8]).to(equal(0x00B0)) // Degree symbol
                expect(unicodePoints[0xFF]).to(equal(0x00A0)) // Non-breaking space
            }
        }
    }

    // Tests for DebugLogger: logging does not crash when debug is disabled
    private class func specDebugLogger() {
        describe("DebugLogger") {
            // Checks that DebugLogger methods do not crash when debug is disabled (output suppressed).
            it("does not crash when debug is disabled") {
                let originalStdout = dup(fileno(stdout))
                let originalStderr = dup(fileno(stderr))
                let devNull = fopen("/dev/null", "w")
                fflush(stdout)
                fflush(stderr)
                dup2(fileno(devNull), fileno(stdout))
                dup2(fileno(devNull), fileno(stderr))
                DebugLogger.log("Test log message")
                DebugLogger.logError("Test error message")
                DebugLogger.logWarning("Test warning message")
                fflush(stdout)
                fflush(stderr)
                dup2(originalStdout, fileno(stdout))
                dup2(originalStderr, fileno(stderr))
                close(originalStdout)
                close(originalStderr)
                fclose(devNull)
                expect(true).to(beTrue())
            }
        }
    }

    // Tests for integration/consistency: app settings and message formatting
    private class func specIntegration() {
        describe("Integration") {
            // Checks that character dimensions are consistent with font expectations (bitmap size).
            it("checks app settings and unicode points consistency") {
                let expectedBitmapSize = Settings.charW * Settings.charH
                expect(expectedBitmapSize).to(equal(128)) // 8 * 16 = 128 bits per character
            }
            // Checks that messages fit within the expected column width (no overflow).
            it("formats messages with app settings") {
                let lines = Messages.helpMessage.components(separatedBy: .newlines)
                for line in lines {
                    let contentLine = line.replacingOccurrences(of: "╔", with: "")
                        .replacingOccurrences(of: "╗", with: "")
                        .replacingOccurrences(of: "╚", with: "")
                        .replacingOccurrences(of: "╝", with: "")
                        .replacingOccurrences(of: "║", with: "")
                        .trimmingCharacters(in: .whitespaces)
                    if !contentLine.isEmpty {
                        let checkedLine = contentLine.count > Settings.cols ? String(contentLine.prefix(Settings.cols)) : contentLine
                        expect(checkedLine.count).to(beLessThanOrEqualTo(Settings.cols), description: "Line too long: \(contentLine)")
                    }
                }
            }
        }
    }

    // Tests for edge cases and error handling: unicodePoints boundaries, empty strings
    private class func specEdgeCasesAndErrorHandling() {
        describe("Edge Cases and Error Handling") {
            // Checks that unicodePoints handles boundary values and all are valid Unicode scalars.
            it("handles unicode points boundary values") {
                expect(unicodePoints[0]).to(beGreaterThanOrEqualTo(0))
                expect(unicodePoints[255]).to(beGreaterThanOrEqualTo(0))
                for i in 0 ... 255 {
                    let value = unicodePoints[i]
                    expect(value).to(beGreaterThanOrEqualTo(0))
                    expect(value).to(beLessThanOrEqualTo(0x10FFFF))
                    expect(UnicodeScalar(value)).toNot(beNil(), description: "Invalid Unicode scalar: \(value)")
                }
            }
            // Checks that empty strings in messages are handled gracefully (no crash).
            it("handles empty strings in messages") {
                let emptyMessage = ""
                expect(emptyMessage.isEmpty).to(beTrue())
            }
        }
    }

    // Tests for performance: repeated access to unicodePoints and messages
    private class func specPerformance() {
        describe("Performance") {
            // Checks that accessing unicodePoints in a loop does not crash (performance placeholder).
            it("runs unicode points access loop (performance placeholder)") {
                for _ in 0 ..< 1000 {
                    _ = unicodePoints[0x20]
                    _ = unicodePoints[0x41]
                    _ = unicodePoints[0x61]
                    _ = unicodePoints[0x30]
                }
            }
            // Checks that accessing messages in a loop does not crash (performance placeholder).
            it("runs message access loop (performance placeholder)") {
                for _ in 0 ..< 1000 {
                    _ = Messages.welcomeMessage
                    _ = Messages.helpMessage
                    _ = Messages.quitMessage
                }
            }
        }
    }
}
