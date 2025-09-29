//
//  AppSettings.swift
//  harryfan-reader
//
//  Created by Vad Tymoshyk on 9/28/25.
//

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
    static let numScreenRows: Int = 24
    // 80x24 text mode with 8x16 font
    static let cols = 80
    static let rows = 24
    static let charW = 8
    static let charH = 16
    static let wrapWidth = 80
    static let wordWrap: Bool = true
    // Quit confirmation
    static let shouldShowQuitMessage: Bool = false
    // Debug mode - enables console logging when true
    static let debug: Bool = false
}

// Debug logging utility
enum DebugLogger {
    static func log(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        guard AppSettings.debug else { return }
        let fileName = (file as NSString).lastPathComponent
        print("[\(fileName):\(line)] \(function): \(message)")
    }

    static func logError(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        guard AppSettings.debug else { return }
        let fileName = (file as NSString).lastPathComponent
        print("🚨 ERROR [\(fileName):\(line)] \(function): \(message)")
    }

    static func logWarning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        guard AppSettings.debug else { return }
        let fileName = (file as NSString).lastPathComponent
        print("⚠️ WARNING [\(fileName):\(line)] \(function): \(message)")
    }
}
