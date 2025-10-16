//
//  SettingsViewModel.swift
//  harryfan-reader
//
//  Created by @vt887 on 10/12/25.
//

import SwiftUI

// View model for managing settings state and logic
class SettingsViewModel: ObservableObject {
    @Published var selectedFont: FontManager.MSDOSFont
    @Published var fontSize: Double
    @Published var removeEmptyLines: Bool
    @Published var wordWrap: Bool
    @Published var wrapWidth: Double
    @Published var enableAntiAliasing: Bool

    // Original values for cancel functionality
    private var originalFont: FontManager.MSDOSFont
    private var originalFontSize: Double
    private var originalRemoveEmptyLines: Bool
    private var originalWordWrap: Bool
    private var originalWrapWidth: Double
    private var originalEnableAntiAliasing: Bool

    init(fontManager: FontManager, document: TextDocument) {
        let currentFont = fontManager.currentFont
        let currentFontSize = fontManager.fontSize
        let currentRemoveEmptyLines = document.removeEmptyLines
        let currentWordWrap = document.wordWrap
        let currentWrapWidth = Double(document.wrapWidth)
        let currentEnableAntiAliasing = Settings.enableAntiAliasing

        selectedFont = currentFont
        fontSize = currentFontSize
        removeEmptyLines = currentRemoveEmptyLines
        wordWrap = currentWordWrap
        wrapWidth = currentWrapWidth
        enableAntiAliasing = currentEnableAntiAliasing

        // Store originals
        originalFont = currentFont
        originalFontSize = currentFontSize
        originalRemoveEmptyLines = currentRemoveEmptyLines
        originalWordWrap = currentWordWrap
        originalWrapWidth = currentWrapWidth
        originalEnableAntiAliasing = currentEnableAntiAliasing
    }

    // Applies the current settings to the models
    func applySettings(fontManager: FontManager, document: TextDocument) {
        fontManager.currentFont = selectedFont
        fontManager.fontSize = fontSize
        document.removeEmptyLines = removeEmptyLines
        document.wordWrap = wordWrap
        document.wrapWidth = Int(wrapWidth)
        Settings.enableAntiAliasing = enableAntiAliasing
        document.reloadWithNewSettings()
    }

    // Cancels changes and restores original values
    func cancelChanges() {
        selectedFont = originalFont
        fontSize = originalFontSize
        removeEmptyLines = originalRemoveEmptyLines
        wordWrap = originalWordWrap
        wrapWidth = originalWrapWidth
        enableAntiAliasing = originalEnableAntiAliasing
    }
}
