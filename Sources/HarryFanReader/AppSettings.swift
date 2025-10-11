//
//  AppSettings.swift
//  harryfan-reader
//
//  Created by @vt887 on 9/28/25.
//

import Foundation
import SwiftUI

// Enum for supported app appearance themes
enum AppAppearance: String, CaseIterable {
    case light
    case dark
    case blue
}

// Enum for global application settings
enum AppSettings {
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
}
