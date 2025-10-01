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

    // Centralized key codes for clarity / future extension
    private enum KeyCode {
        static let f10: UInt16 = 109
        static let escape: UInt16 = 53
        static let f3: UInt16 = 99
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
        default:
            return event
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
                ScreenView(document: document, contentToDisplay: Messages.quitMessage, displayRows: AppSettings.rows - 2, rowOffset: 1)
                    .environmentObject(fontManager)
                    .frame(height: CGFloat(AppSettings.rows - 2) * CGFloat(ScreenView.charH))
            } else {
                ScreenView(document: document, displayRows: AppSettings.rows - 2, rowOffset: 1)
                    .environmentObject(fontManager)
                    .frame(height: CGFloat(AppSettings.rows - 2) * CGFloat(ScreenView.charH))
                    .onAppear {
                        if document.fileName.isEmpty { document.loadWelcomeText() }
                        DebugLogger.log("Main content area appeared")
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
