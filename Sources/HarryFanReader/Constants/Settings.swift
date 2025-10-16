//
//  Settings.swift
//  harryfan-reader
//
//  Created by automated-refactor on 10/16/25.
//

import Foundation
import SwiftUI

// Enum for supported app appearance themes
enum AppAppearance: String, CaseIterable {
    case light
    case dark
    case blue
}

// Class for global application settings
class Settings {
    // Constants
    static let appName: String = "HarryFan Reader"
    static let homeDir: String = "~/.harryfan"
    static let fontFileName: String = "ddd.8x16"
    static let defaultFontFileName: String = "vdu.8x16"
    static let appearance: AppAppearance = .blue
    // 80x24 text mode with 8x16 font
    static let cols = 80
    static let rows = 24
    static let charW = 8
    static let charH = 16
    static let wrapWidth = 80

    // Persisted settings
    static var wordWrap: Bool {
        get { UserDefaults.standard.object(forKey: "wordWrap") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "wordWrap") }
    }

    static var wordWrapLabel: String {
        wordWrap ? "Unwrap" : "Wrap"
    }

    // Quit confirmation (persisted)
    static var shouldShowQuitMessage: Bool {
        get { UserDefaults.standard.object(forKey: "shouldShowQuitMessage") as? Bool ?? false }
        set { UserDefaults.standard.set(newValue, forKey: "shouldShowQuitMessage") }
    }

    // Anti-aliasing for smoother text rendering (configurable via settings)
    static var enableAntiAliasing: Bool {
        get { UserDefaults.standard.object(forKey: "enableAntiAliasing") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "enableAntiAliasing") }
    }

    // Debug mode - enables console logging when true (persisted)
    static var debug: Bool {
        get { UserDefaults.standard.object(forKey: "debug") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "debug") }
    }

    // Whether to show the Status Bar icon (persisted). Default: false
    static var showStatusBarIcon: Bool {
        get { UserDefaults.standard.object(forKey: "showStatusBarIcon") as? Bool ?? false }
        set { UserDefaults.standard.set(newValue, forKey: "showStatusBarIcon") }
    }
}
