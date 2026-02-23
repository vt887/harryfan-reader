//
//  SettingsView.swift
//  harryfan-reader
//
//  Created by @vt887 on 9/1/25.
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

    // View model for settings
    @StateObject private var viewModel = SettingsViewModel(fontManager: FontManager(), document: TextDocument())

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

                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(Color.black.opacity(0.2), lineWidth: 0.5),
                        )
                        .scaleEffect(1.0)

                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(Color.black.opacity(0.2), lineWidth: 0.5),
                        )
                        .scaleEffect(1.0)
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
                    Picker("Font", selection: $viewModel.selectedFont) {
                        ForEach(FontManager.MSDOSFont.allCases, id: \.self) { font in
                            Text(font.displayName).tag(font)
                        }
                    }

                    HStack {
                        Text("Font Size")
                        Slider(value: $viewModel.fontSize, in: 8 ... 32, step: 1)
                        Text("\(Int(viewModel.fontSize))")
                            .frame(width: 30)
                    }
                }

                Section("Text Processing") {
                    Toggle("Remove excessive empty lines", isOn: $viewModel.removeEmptyLines)
                        .help("Automatically remove multiple consecutive empty lines")

                    Toggle("Word wrap", isOn: $viewModel.wordWrap)
                        .help("Automatically wrap long lines to fit the display width")

                    if viewModel.wordWrap {
                        HStack {
                            Text("Wrap width")
                            Slider(value: $viewModel.wrapWidth, in: 40 ... 200, step: 1)
                            Text("\(Int(viewModel.wrapWidth))")
                                .frame(width: 40)
                        }
                        .help("Maximum number of characters per line")
                    }
                }

                Section("Display") {
                    Toggle("Enable anti-aliasing", isOn: $viewModel.enableAntiAliasing)
                        .help("Smooth text rendering for better visual quality")

                    Toggle("Show status bar", isOn: $viewModel.showStatusBar)
                        .help("Display the status bar icon for quick access to app controls")
                }
            }
            .formStyle(.grouped)

            // Bottom button bar
            HStack {
                Spacer()

                // Cancel button restores original values and dismisses
                Button("Cancel") {
                    viewModel.cancelChanges()
                    dismiss()
                }
                .keyboardShortcut(.escape)

                // Submit button applies changes and dismisses
                Button("Submit") {
                    viewModel.applySettings(fontManager: fontManager, document: document)
                    dismiss()
                }
                .keyboardShortcut(.return)
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
        .frame(width: 400, height: 500)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            // Initialize view model with current values
            viewModel.selectedFont = fontManager.currentFont
            viewModel.fontSize = fontManager.fontSize
            viewModel.removeEmptyLines = document.removeEmptyLines
            viewModel.wordWrap = document.wordWrap
            viewModel.wrapWidth = Double(document.wrapWidth)
            viewModel.enableAntiAliasing = Settings.enableAntiAliasing
            viewModel.showStatusBar = Settings.showStatusBar
        }
    }
}

// Preview for SettingsView
#Preview {
    SettingsView()
        .environmentObject(FontManager())
        .environmentObject(TextDocument())
}
