//
//  AppSettings.swift
//  harryfan-reader
//
//  Created by @vt887 on 9/28/25.
//

import Foundation
import SwiftUI

/// Enum for supported app appearance themes
enum AppAppearance: String, CaseIterable {
    case light
    case dark
    case blue
}

/// Enum for global application settings
enum AppSettings {
    static let appName: String = "HarryFan Reader"
    static let homeDir: String = "~/.harryfan"
    static let defaultFontFileName: String = "vdu.8x16"
    /// Currently selected font (persisted)
    static var fontFileName: String {
        get { UserDefaults.standard.string(forKey: "fontFileName") ?? defaultFontFileName }
        set { UserDefaults.standard.set(newValue, forKey: "fontFileName") }
    }
    static let appearance: AppAppearance = .blue
    // 80x24 text mode with 8x16 font
    static let cols = 80
    static let rows = 24
    static let defaultCharW: Int = 8
    static let defaultCharH: Int = 16
    static let wrapWidth = 80
    static let wordWrap: Bool = true

    /// Character width scale factor (persisted, default 1.0)
    static var charWScale: CGFloat {
        get { UserDefaults.standard.object(forKey: "charWScale") as? CGFloat ?? 1.0 }
        set { UserDefaults.standard.set(newValue, forKey: "charWScale") }
    }

    /// Character height scale factor (persisted, default 1.0)
    static var charHScale: CGFloat {
        get { UserDefaults.standard.object(forKey: "charHScale") as? CGFloat ?? 1.0 }
        set { UserDefaults.standard.set(newValue, forKey: "charHScale") }
    }

    /// Current character width (scaled, as Int for font loading)
    static var charW: Int {
        defaultCharW
    }

    /// Current character height (scaled, as Int for font loading)
    static var charH: Int {
        defaultCharH
    }

    /// Current character width for rendering (scaled as CGFloat)
    static var charWRendering: CGFloat {
        CGFloat(defaultCharW) * charWScale
    }

    /// Current character height for rendering (scaled as CGFloat)
    static var charHRendering: CGFloat {
        CGFloat(defaultCharH) * charHScale
    }
    /// Quit confirmation (persisted)
    static var shouldShowQuitMessage: Bool {
        get { UserDefaults.standard.object(forKey: "shouldShowQuitMessage") as? Bool ?? false }
        set { UserDefaults.standard.set(newValue, forKey: "shouldShowQuitMessage") }
    }

    /// Anti-aliasing for smoother text rendering (configurable via settings)
    static var enableAntiAliasing: Bool {
        get { UserDefaults.standard.object(forKey: "enableAntiAliasing") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "enableAntiAliasing") }
    }

    /// Debug mode - enables console logging when true (persisted)
    static var debug: Bool {
        get { UserDefaults.standard.object(forKey: "debug") as? Bool ?? false }
        set { UserDefaults.standard.set(newValue, forKey: "debug") }
    }
}
