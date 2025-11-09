//
//  Settings.swift
//  harryfan-reader
//
//  Created by @vt887 on 10/16/25.
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
    static let tmpDirName: String = "/tmp"
    static let fontFileName: String = "ddd.8x16"
    static let defaultFontFileName: String = "vdu.8x16"
    static let appearance: AppAppearance = .blue
    static let overlayAnimationDuration: Double = 0.25
    // 80x24 text mode with 8x16 font
    static let cols = 80
    static let rows = 24
    static let charW = 8
    static let charH = 16
    static let wrapWidth = 80
    // LibraryURL
    static let libraryURL = "https://drive.google.com/drive/u/0/folders/1F7DAtaA3Yw2DeeEtF0WbUook8IVNNz6S"

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

    // Whether to show the Status Bar (persisted). Default: false
    private static let _showStatusBarKey = "showStatusBar"
    static var showStatusBar: Bool {
        get {
            let defaults = UserDefaults.standard
            // If new key exists, prefer it
            if let val = defaults.object(forKey: _showStatusBarKey) as? Bool {
                return val
            }
            return false
        }
        set {
            UserDefaults.standard.set(newValue, forKey: _showStatusBarKey)
        }
    }

    // Mouse usage setting
    static var useMouse: Bool {
        get { UserDefaults.standard.object(forKey: "useMouse") as? Bool ?? false }
        set { UserDefaults.standard.set(newValue, forKey: "useMouse") }
    }

    // Returns the number of visible lines in the viewport (rows - 2 for title and action bars)
    static var visibleLines: Int {
        rows - 2
    }

    // Returns the window size for 80x24 character grid
    static func windowSize() -> CGSize {
        CGSize(width: CGFloat(cols * charW), height: CGFloat(rows * charH))
    }

    // Returns size for a specific number of rows (useful for partial screen views)
    static func windowSize(rows displayRows: Int) -> CGSize {
        CGSize(width: CGFloat(cols * charW), height: CGFloat(displayRows * charH))
    }
}
