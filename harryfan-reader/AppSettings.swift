//
//  AppSettings.swift
//  harryfan-reader
//
//  Created by Vad Tymoshyk on 9/28/25.
//

import SwiftUI

enum AppAppearance: String, CaseIterable {
    case light
    case dark
    case blue
}

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
}
