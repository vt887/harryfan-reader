//
//  ContentView.swift
//  harryfan-reader
//
//  Created by @vt887 on 9/1/25.
//

import AppKit
import SwiftUI
import UniformTypeIdentifiers

// Main content view for the app
struct ContentView: View {
    @StateObject private var document = TextDocument()
    @EnvironmentObject var fontManager: FontManager
    @EnvironmentObject var bookmarkManager: BookmarkManager
    @EnvironmentObject var recentFilesManager: RecentFilesManager

    @State private var showingFilePicker = false
    @State private var showingSearch = false
    @State private var showingBookmarks = false
    @State private var lastSearchTerm: String = ""
    @State private var showingSettings = false
    @State private var showingGotoDialog = false
    @State private var gotoLineNumber = ""

    init() {
        DebugLogger.log("ContentView initializing...")
    }

    var body: some View {
        VStack(spacing: 0) {
            TitleBar(document: document)
            MainContentScreenView(document: document, showingFilePicker: $showingFilePicker)
            MenuBar(document: document)
        }
        .frame(
            width: CGFloat(AppSettings.cols * AppSettings.charW),
            height: CGFloat(AppSettings.rows * AppSettings.charH)
        )
        .background(Colors.theme.background)
        .fileImporter(isPresented: $showingFilePicker,
                      allowedContentTypes: [UTType.plainText],
                      allowsMultipleSelection: false,
                      onCompletion: handleFileImport)
        .sheet(isPresented: $showingSearch) {
            SearchView(isPresented: $showingSearch,
                       document: document,
                       lastSearchTerm: $lastSearchTerm)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(fontManager)
                .environmentObject(document)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .applyNotifications(document: document,
                            showingSearch: $showingSearch,
                            showingBookmarks: $showingBookmarks,
                            showingFilePicker: $showingFilePicker,
                            lastSearchTerm: $lastSearchTerm)
    }

    // File Import Handler
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case let .success(urls):
            if let url = urls.first {
                document.openFile(at: url)
                recentFilesManager.addRecentFile(url: url)
            }
        case let .failure(error):
            DebugLogger.logError("Error selecting file: \(error)")
        }
    }
}

// Private struct for the main content screen view
private struct MainContentScreenView: View {
    @ObservedObject var document: TextDocument
    @EnvironmentObject var fontManager: FontManager
    @State private var quitKeysMonitor: Any?
    @Binding var showingFilePicker: Bool

    // Overlay management
    @State private var overlayLayers: [ScreenLayer] = []
    @State private var welcomeOverlayId: UUID? = nil

    // Centralized key codes for clarity / future extension
    private enum KeyCode {
        static let f10: UInt16 = 109
        static let escape: UInt16 = 53
        static let f3: UInt16 = 99
        static let f7: UInt16 = 98 // Jump to start
        static let f8: UInt16 = 100 // Jump to end
    }

    // Unified quit handling for F10 / Esc
    private func handleQuitKey() {
        if AppSettings.shouldShowQuitMessage, !document.shouldShowQuitMessage {
            document.shouldShowQuitMessage = true
            return
        }
        NSApp.terminate(nil)
    }

    // Event handler separated for readability & testability
    private func handleKeyEvent(_ event: NSEvent) -> NSEvent? {
        // First: if welcome overlay is showing, remove it on ANY key
        if let id = welcomeOverlayId {
            let removingId = id
            DispatchQueue.main.async {
                overlayLayers.removeAll { $0.id == removingId }
                welcomeOverlayId = nil
                DebugLogger.log("Welcome overlay removed (keyCode=\(event.keyCode))")
            }
            // Continue processing this key normally below
        }
        switch event.keyCode {
        case KeyCode.f10:
            DebugLogger.log("F10 key pressed")
            handleQuitKey()
            return nil
        case KeyCode.escape:
            if AppSettings.debug { // Esc only when debug enabled
                DebugLogger.log("Esc key pressed (debug mode)")
                handleQuitKey()
                return nil
            }
            return event
        case KeyCode.f3:
            DebugLogger.log("F3 key pressed - opening file picker")
            showingFilePicker = true
            return nil
        case KeyCode.f7:
            DebugLogger.log("F7 key pressed - goto start")
            document.gotoStart()
            return nil
        case KeyCode.f8:
            DebugLogger.log("F8 key pressed - goto end")
            document.gotoEnd()
            return nil
        default:
            return event // Pass through other keys
        }
    }

    // Refactored monitor installer
    private func installQuitMonitor() {
        guard quitKeysMonitor == nil else { return }
        quitKeysMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown, handler: handleKeyEvent)
    }

    private func removeQuitMonitor() {
        if let monitor = quitKeysMonitor {
            NSEvent.removeMonitor(monitor)
            quitKeysMonitor = nil
        }
    }

    var body: some View {
        Group {
            if document.shouldShowQuitMessage {
                ScreenView(document: document, contentToDisplay: Messages.quitMessage, displayRows: AppSettings.rows - 2, rowOffset: 1, overlayLayers: .constant([]))
                    .environmentObject(fontManager)
                    .frame(height: CGFloat(AppSettings.rows - 2) * CGFloat(ScreenView.charH))
            } else {
                ScreenView(document: document, displayRows: AppSettings.rows - 2, rowOffset: 1, overlayLayers: $overlayLayers)
                    .environmentObject(fontManager)
                    .frame(height: CGFloat(AppSettings.rows - 2) * CGFloat(ScreenView.charH))
                    .onAppear {
                        // Do NOT load welcome text into the document; keep base empty so when overlay is removed the screen clears properly.
                        if document.fileName.isEmpty, document.totalLines == 0 {
                            // Leave document content empty until a file is opened.
                            DebugLogger.log("Skipping loadWelcomeText; using overlay only")
                        }
                        DebugLogger.log("Main content area appeared")
                        // Add welcome overlay if not already present
                        if welcomeOverlayId == nil, document.fileName.isEmpty {
                            let layer = ScreenView(document: document, displayRows: AppSettings.rows - 2, overlayLayers: .constant([])).centeredOverlayLayer(from: Messages.welcomeMessage)
                            welcomeOverlayId = layer.id
                            overlayLayers.append(layer)
                            DebugLogger.log("Welcome overlay added (id=\(layer.id))")
                        }
                        installQuitMonitor()
                    }
            }
        }
        .onAppear { installQuitMonitor() }
        .onDisappear { removeQuitMonitor() }
    }
}

#Preview {
    ContentView()
        .environmentObject(FontManager())
        .environmentObject(BookmarkManager())
        .environmentObject(RecentFilesManager())
}
