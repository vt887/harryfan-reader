//
//  SettingsView.swift
//  harryfan-reader
//
//  Created by Vad Tymoshyk on 9/1/25.
//

import SwiftUI

// View for displaying and managing application settings
struct SettingsView: View {
    // Font manager environment object
    @EnvironmentObject var fontManager: FontManager
    // Document environment object
    @EnvironmentObject var document: TextDocument
    // Dismiss environment value for closing the view
    @Environment(\.dismiss) private var dismiss

    // Currently selected font
    @State private var selectedFont: FontManager.MSDOSFont = .vdu8x16
    // Current font size
    @State private var fontSize: Double = 16.0
    // Remove excessive empty lines toggle
    @State private var removeEmptyLines: Bool = true
    // Word wrap toggle
    @State private var wordWrap: Bool = true
    // Wrap width value
    @State private var wrapWidth: Double = 80.0
    // Original font for cancel functionality
    @State private var originalFont: FontManager.MSDOSFont = .vdu8x16
    // Original font size for cancel functionality
    @State private var originalFontSize: Double = 16.0
    // Original remove empty lines value for cancel functionality
    @State private var originalRemoveEmptyLines: Bool = true
    // Original word wrap value for cancel functionality
    @State private var originalWordWrap: Bool = true
    // Original wrap width value for cancel functionality
    @State private var originalWrapWidth: Double = 80.0

    // Main view body rendering the settings UI
    var body: some View {
        VStack(spacing: 0) {
            // macOS-style title bar with window controls
            HStack {
                // Window control buttons (red, yellow, green)
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(Color.black.opacity(0.2), lineWidth: 0.5),
                        )
                        .scaleEffect(1.0)
                        .onTapGesture {
                            dismiss()
                        }
                        .onHover { _ in
                            // Hover effect would go here
                        }

                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(Color.black.opacity(0.2), lineWidth: 0.5),
                        )
                        .scaleEffect(1.0)
                        .onTapGesture {
                            // Minimize functionality
                        }
                        .onHover { _ in
                            // Hover effect would go here
                        }

                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(Color.black.opacity(0.2), lineWidth: 0.5),
                        )
                        .scaleEffect(1.0)
                        .onTapGesture {
                            // Maximize functionality
                        }
                        .onHover { _ in
                            // Hover effect would go here
                        }
                }
                .padding(.leading, 12)

                Spacer()

                Text("Settings")
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                // Invisible spacer to center the title
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 12, height: 12)

                    Circle()
                        .fill(Color.clear)
                        .frame(width: 12, height: 12)

                    Circle()
                        .fill(Color.clear)
                        .frame(width: 12, height: 12)
                }
                .padding(.trailing, 12)
            }
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(NSColor.separatorColor)),
                alignment: .bottom,
            )

            // Settings content
            Form {
                Section("Font Settings") {
                    Picker("Font", selection: $selectedFont) {
                        ForEach(FontManager.MSDOSFont.allCases, id: \.self) { font in
                            Text(font.displayName).tag(font)
                        }
                    }

                    HStack {
                        Text("Font Size")
                        Slider(value: $fontSize, in: 8 ... 32, step: 1)
                        Text("\(Int(fontSize))")
                            .frame(width: 30)
                    }
                }

                Section("Text Processing") {
                    Toggle("Remove excessive empty lines", isOn: $removeEmptyLines)
                        .help("Automatically remove multiple consecutive empty lines")

                    Toggle("Word wrap", isOn: $wordWrap)
                        .help("Automatically wrap long lines to fit the display width")

                    if wordWrap {
                        HStack {
                            Text("Wrap width")
                            Slider(value: $wrapWidth, in: 40 ... 200, step: 1)
                            Text("\(Int(wrapWidth))")
                                .frame(width: 40)
                        }
                        .help("Maximum number of characters per line")
                    }
                }

                Section("About") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("HarryFan Reader")
                            .font(.headline)
                        Text("A retro-style text viewer")
                            .font(.caption)
                        Text("Supports CP866 encoding and MS-DOS fonts")
                            .font(.caption)
                        Text("Version \(ReleaseInfo.version).\(ReleaseInfo.build)")
                            .font(.caption)
                    }
                }
            }
            .formStyle(.grouped)

            // Bottom button bar
            HStack {
                Spacer()

                // Cancel button restores original values and dismisses
                Button("Cancel") {
                    // Restore original values
                    selectedFont = originalFont
                    fontSize = originalFontSize
                    removeEmptyLines = originalRemoveEmptyLines
                    wordWrap = originalWordWrap
                    wrapWidth = originalWrapWidth
                    dismiss()
                }
                .keyboardShortcut(.escape)

                // Submit button applies changes and dismisses
                Button("Submit") {
                    // Apply changes
                    fontManager.currentFont = selectedFont
                    fontManager.fontSize = fontSize
                    document.removeEmptyLines = removeEmptyLines
                    document.wordWrap = wordWrap
                    document.wrapWidth = Int(wrapWidth)

                    // Reload file with new settings if a file is open
                    if !document.fileName.isEmpty {
                        document.reloadWithNewSettings()
                    }

                    dismiss()
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(NSColor.separatorColor)),
                alignment: .top,
            )
        }
        .frame(width: 450, height: 400)
        .background(Color(NSColor.windowBackgroundColor))
        // onAppear stores original values for cancel functionality and sets current values
        .onAppear {
            // Store original values for cancel functionality
            originalFont = fontManager.currentFont
            originalFontSize = fontManager.fontSize
            originalRemoveEmptyLines = document.removeEmptyLines
            originalWordWrap = document.wordWrap
            originalWrapWidth = Double(document.wrapWidth)

            // Set current values
            selectedFont = fontManager.currentFont
            fontSize = fontManager.fontSize
            removeEmptyLines = document.removeEmptyLines
            wordWrap = document.wordWrap
            wrapWidth = Double(document.wrapWidth)
        }
    }
}

// Preview for SettingsView
#Preview {
    SettingsView()
        .environmentObject(FontManager())
}
