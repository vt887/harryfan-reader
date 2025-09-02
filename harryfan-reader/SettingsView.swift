//
//  SettingsView.swift
//  harryfan-reader
//
//  Created by Vad Tymoshyk on 9/1/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var fontManager: FontManager
    @EnvironmentObject var document: TextDocument
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedFont: FontManager.MSDOSFont = .vdu8x16
    @State private var fontSize: Double = 16.0
    @State private var removeEmptyLines: Bool = true
    @State private var wordWrap: Bool = true
    @State private var wrapWidth: Double = 80.0
    @State private var originalFont: FontManager.MSDOSFont = .vdu8x16
    @State private var originalFontSize: Double = 16.0
    @State private var originalRemoveEmptyLines: Bool = true
    @State private var originalWordWrap: Bool = true
    @State private var originalWrapWidth: Double = 80.0
    
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
                                .stroke(Color.black.opacity(0.2), lineWidth: 0.5)
                        )
                        .scaleEffect(1.0)
                        .onTapGesture {
                            dismiss()
                        }
                        .onHover { isHovered in
                            // Hover effect would go here
                        }
                    
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(Color.black.opacity(0.2), lineWidth: 0.5)
                        )
                        .scaleEffect(1.0)
                        .onTapGesture {
                            // Minimize functionality
                        }
                        .onHover { isHovered in
                            // Hover effect would go here
                        }
                    
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(Color.black.opacity(0.2), lineWidth: 0.5)
                        )
                        .scaleEffect(1.0)
                        .onTapGesture {
                            // Maximize functionality
                        }
                        .onHover { isHovered in
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
                alignment: .bottom
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
                        Slider(value: $fontSize, in: 8...32, step: 1)
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
                            Slider(value: $wrapWidth, in: 40...200, step: 1)
                            Text("\(Int(wrapWidth))")
                                .frame(width: 40)
                        }
                        .help("Maximum number of characters per line")
                    }
                }
                
                Section("About") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Harryfan Reader")
                            .font(.headline)
                        Text("A retro-style text viewer for MacOS")
                            .font(.caption)
                        Text("Supports CP866 encoding and MS-DOS fonts")
                            .font(.caption)
                        Text("Version 1.0")
                            .font(.caption)
                    }
                }
            }
            .formStyle(.grouped)
            
            // Bottom button bar
            HStack {
                Spacer()
                
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
                alignment: .top
            )
        }
        .frame(width: 450, height: 400)
        .background(Color(NSColor.windowBackgroundColor))
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

#Preview {
    SettingsView()
        .environmentObject(FontManager())
}
