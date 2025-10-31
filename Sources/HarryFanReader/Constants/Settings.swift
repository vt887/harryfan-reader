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

    // Global UI scale factor (persisted). Default: 1.0
    private static let _scaleFactorKey = "scaleFactor"
    static var scaleFactor: CGFloat {
        get {
            let defaults = UserDefaults.standard
            if let val = defaults.object(forKey: _scaleFactorKey) as? Double {
                return CGFloat(val)
            }
            return 1.0
        }
        set {
            UserDefaults.standard.set(Double(newValue), forKey: _scaleFactorKey)
        }
    }

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
    // Migration: older versions used the `showStatusBarIcon` key — migrate on first read.
    private static let _showStatusBarKeyNew = "showStatusBar"
    static var showStatusBar: Bool {
        get {
            let defaults = UserDefaults.standard
            // If new key exists, prefer it
            if let val = defaults.object(forKey: _showStatusBarKeyNew) as? Bool {
                return val
            }
            return false
        }
        set {
            UserDefaults.standard.set(newValue, forKey: _showStatusBarKeyNew)
        }
    }

    // Mouse usage setting
    static var useMouse: Bool {
        get { UserDefaults.standard.object(forKey: "useMouse") as? Bool ?? false }
        set { UserDefaults.standard.set(newValue, forKey: "useMouse") }
    }

    private static var baseWindowSize: CGSize {
        CGSize(width: CGFloat(cols) * CGFloat(charW), height: CGFloat(rows) * CGFloat(charH))
    }

    /// Pixel size of a single character cell after scale applied
    static func pixelCharSize(scale: CGFloat? = nil) -> CGSize {
        let s = scale ?? scaleFactor
        return CGSize(width: CGFloat(charW) * s, height: CGFloat(charH) * s)
    }

    /// Pixel size of an arbitrary rows x cols content area after scale applied
    static func contentSize(rows: Int, cols: Int, scale: CGFloat? = nil) -> CGSize {
        let p = pixelCharSize(scale: scale)
        return CGSize(width: CGFloat(cols) * p.width, height: CGFloat(rows) * p.height)
    }

    static func windowSize(scale: CGFloat? = nil) -> CGSize {
        // Scaled window size for full app (Settings.rows x Settings.cols)
        contentSize(rows: rows, cols: cols, scale: scale)
     }

     /// Returns a compact telemetry string (not PII) for debug logs.
     static func telemetryString() -> String {
         // Collect small set of non-sensitive telemetry values useful for debugging
         let app = appName
         let version = ReleaseInfo.version
         let build = ReleaseInfo.build
         let scale = String(format: "%.2f", Double(scaleFactor))
         let appearanceStr = appearance.rawValue
         let wrap = wordWrap ? "wrap" : "nowrap"
         let aa = enableAntiAliasing ? "aa:on" : "aa:off"
         let os = ProcessInfo.processInfo.operatingSystemVersionString
         return "app=\(app) ver=\(version) (build:\(build)) scale=\(scale) appearance=\(appearanceStr) \(wrap) \(aa) os=\(os)"
     }
}
