//
//  ContentView.swift
//  harryfan-reader
//
//  Created by @vt887 on 9/1/25.
//

import AppKit
import Foundation
import SwiftUI
import UniformTypeIdentifiers

// Main content view for the app
struct ContentView: View {
    @StateObject private var document = TextDocument()
    @EnvironmentObject var fontManager: FontManager
    @EnvironmentObject var bookmarkManager: BookmarkManager
    @EnvironmentObject var recentFilesManager: RecentFilesManager
    @EnvironmentObject var statusBarManager: StatusBarManager

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
            MainContentScreenView(document: document, recentFilesManager: recentFilesManager, showingFilePicker: $showingFilePicker)
            BottomBar(document: document)
        }
        .frame(
            width: CGFloat(AppSettings.cols * AppSettings.charW),
            height: CGFloat(AppSettings.rows * AppSettings.charH),
        )
        .background(Colors.theme.background)
        .sheet(isPresented: $showingSearch) {
            SearchView(isPresented: $showingSearch, document: document, lastSearchTerm: $lastSearchTerm)
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
}

// Private struct for the main content screen view
private struct MainContentScreenView: View {
    @ObservedObject var document: TextDocument
    @EnvironmentObject var fontManager: FontManager
    @EnvironmentObject var overlayManager: OverlayManager
    var recentFilesManager: RecentFilesManager
    @State private var quitKeysMonitor: Any?
    @Binding var showingFilePicker: Bool

    // Overlay management
    @State private var overlayLayers: [ScreenLayer] = []
    @State private var overlayOpacities: [UUID: Double] = [:] // opacity per overlay for fade animations
    @State private var welcomeOverlayId: UUID? = nil
    @State private var helpOverlayId: UUID? = nil // help overlay tracking
    @State private var fileTextOverlayId: UUID? = nil // file text overlay tracking

    // Overlay state for key handling
    private enum ActiveOverlay {
        case none
        case welcome
        case help
        case quit
        case custom
    }

    @State private var activeOverlay: ActiveOverlay = .none

    private func removeWelcomeOverlayIfPresent(fadeDuration: Double = 0.25) {
        if let wId = welcomeOverlayId {
            removeOverlay(id: wId, fadeDuration: fadeDuration)
            welcomeOverlayId = nil
            DebugLogger.log("Welcome overlay removed (auto)")
        }
    }

    private func addOverlay(kind: OverlayKind, fadeDuration: Double = 0.25) -> UUID {
        overlayManager.removeHelpOverlay()
        let layer = OverlayFactory.make(kind: kind, rows: AppSettings.rows - 2, cols: AppSettings.cols)
        let id = layer.id
        overlayLayers.append(layer)
        overlayOpacities[id] = 0.0
        withAnimation(.easeInOut(duration: fadeDuration)) {
            overlayOpacities[id] = 1.0
        }
        // Set activeOverlay based on kind
        switch kind {
        case .welcome: activeOverlay = .welcome
        case .help: activeOverlay = .help
        case .quit: activeOverlay = .quit
        case let .custom(msg):
            if msg == Messages.quitMessage {
                activeOverlay = .quit
            } else {
                activeOverlay = .custom
            }
        default: activeOverlay = .custom
        }
        return id
    }

    private func removeOverlay(id: UUID, fadeDuration: Double = 0.25) {
        guard overlayLayers.contains(where: { $0.id == id }) else { return }
        // Animate opacity to zero then remove layer
        withAnimation(.easeInOut(duration: fadeDuration)) {
            overlayOpacities[id] = 0.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + fadeDuration) {
            overlayLayers.removeAll { $0.id == id }
            overlayOpacities[id] = nil
            // Reset activeOverlay if no overlays left
            if overlayLayers.isEmpty { activeOverlay = .none }
        }
    }

    // Centralized key codes for clarity / future extension
    private enum KeyCode {
        static let f1: UInt16 = 122 // Show/Hide help overlay
        static let f2: UInt16 = 120 // Show file text overlay
        static let f10: UInt16 = 109
        static let escape: UInt16 = 53
        static let f3: UInt16 = 99
        static let f7: UInt16 = 98 // Jump to start
        static let f8: UInt16 = 100 // Jump to end
        static let yKey: UInt16 = 16 // Y key
        static let nKey: UInt16 = 45 // N key
    }

    // Unified quit handling for F10 / Esc
    private func handleQuitKey() {
        if AppSettings.shouldShowQuitMessage, !document.shouldShowQuitMessage {
            document.shouldShowQuitMessage = true
            return
        }
        NSApp.terminate(nil)
    }

    // File Import Handler (now here)
    // Always removes HelpOverlay and WelcomeOverlay before opening a file
    private func handleFileImport(_ result: Result<[URL], Error>) {
        overlayManager.removeHelpOverlay()
        removeWelcomeOverlayIfPresent()
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

    // Event handler separated for readability & testability
    private func handleKeyEvent(_ event: NSEvent) -> NSEvent? {
        DebugLogger.log("Key pressed: keyCode=\(event.keyCode), characters='\(event.charactersIgnoringModifiers ?? "")', activeOverlay=\(activeOverlay)")
        switch activeOverlay {
        case .quit:
            // Accept both uppercase and lowercase Y/N
            if event.charactersIgnoringModifiers?.lowercased() == "y" {
                DebugLogger.log("Quit overlay: 'y' pressed, terminating app.")
                NSApp.terminate(nil)
            } else if event.charactersIgnoringModifiers?.lowercased() == "n" {
                DebugLogger.log("Quit overlay: 'n' pressed, cancelling quit dialog.")
                document.shouldShowQuitMessage = false
                activeOverlay = .none
                // Remove the quit overlay layer
                if let quitId = fileTextOverlayId {
                    removeOverlay(id: quitId)
                    fileTextOverlayId = nil
                }
            } else {
                DebugLogger.log("Quit overlay: ignored key.")
            }
            return nil
        case .welcome:
            // Dismiss on any key
            if let wId = welcomeOverlayId {
                DebugLogger.log("Welcome overlay: any key pressed, dismissing overlay.")
                removeOverlay(id: wId)
                welcomeOverlayId = nil
                activeOverlay = .none
                return nil
            }
        case .help:
            // Dismiss on Escape only
            if event.keyCode == KeyCode.escape {
                DebugLogger.log("Help overlay: ESC pressed, dismissing overlay.")
                if let hId = helpOverlayId {
                    removeOverlay(id: hId)
                    helpOverlayId = nil
                    activeOverlay = .none
                }
                return nil
            } else {
                DebugLogger.log("Help overlay: ignored key.")
                return nil // Ignore all other keys
            }
        case .custom:
            // Dismiss on Escape
            if event.keyCode == KeyCode.escape {
                DebugLogger.log("Custom overlay: ESC pressed, dismissing all overlays.")
                overlayLayers.removeAll()
                overlayOpacities.removeAll()
                activeOverlay = .none
                return nil
            } else {
                DebugLogger.log("Custom overlay: ignored key.")
                return nil // Ignore all other keys
            }
        case .none:
            break // Normal key handling below
        }
        // Remove welcome overlay on first key if present
        if let wId = welcomeOverlayId {
            removeOverlay(id: wId)
            welcomeOverlayId = nil
            DebugLogger.log("Welcome overlay removed (keyCode=\(event.keyCode))")
        }
        // Always remove help overlay on any key event
        overlayManager.removeHelpOverlay()

        // F2 toggles word wrap
        if event.keyCode == KeyCode.f2 {
            document.toggleWordWrap()
            DebugLogger.log("Word wrap toggled (keyCode=\(event.keyCode))")
            return nil
        }
        // F1 toggle help
        if event.keyCode == KeyCode.f1 {
            if let hId = helpOverlayId {
                removeOverlay(id: hId)
                helpOverlayId = nil
                DebugLogger.log("Help overlay hidden (keyCode=\(event.keyCode))")
            } else {
                // Ensure welcome removed before showing help
                if let wId = welcomeOverlayId {
                    removeOverlay(id: wId)
                    welcomeOverlayId = nil
                    DebugLogger.log("Welcome overlay removed before showing help")
                }
                helpOverlayId = addOverlay(kind: .help)
                DebugLogger.log("Help overlay shown (id=\(helpOverlayId!))")
            }
            return nil
        }
        switch event.keyCode {
        case KeyCode.f10:
            DebugLogger.log("F10 key pressed")
            document.shouldShowQuitMessage = true
            // Set the quit overlay and activeOverlay explicitly
            let quitId = addOverlay(kind: .quit)
            fileTextOverlayId = quitId
            DebugLogger.log("Quit overlay shown (id=\(quitId))")
            return nil
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
        // Number keys for menu items (1-10)
        case 18: // 1 key
            DebugLogger.log("1 key pressed - Help")
            if let hId = helpOverlayId {
                removeOverlay(id: hId)
                helpOverlayId = nil
                DebugLogger.log("Help overlay hidden")
            } else {
                if let wId = welcomeOverlayId {
                    removeOverlay(id: wId)
                    welcomeOverlayId = nil
                }
                helpOverlayId = addOverlay(kind: .help)
                DebugLogger.log("Help overlay shown")
            }
            return nil
        case 19: // 2 key
            DebugLogger.log("2 key pressed - Wrap")
            document.toggleWordWrap()
            return nil
        case 20: // 3 key
            DebugLogger.log("3 key pressed - Open")
            showingFilePicker = true
            return nil
        case 21: // 4 key
            DebugLogger.log("4 key pressed - Search")
            // TODO: Implement search functionality
            return nil
        case 22: // 5 key
            DebugLogger.log("5 key pressed - Goto")
            // TODO: Implement goto functionality
            return nil
        case 23: // 6 key
            DebugLogger.log("6 key pressed - Bookmark")
            // TODO: Implement bookmark functionality
            return nil
        case 24: // 7 key
            DebugLogger.log("7 key pressed - Start")
            document.gotoStart()
            return nil
        case 25: // 8 key
            DebugLogger.log("8 key pressed - End")
            document.gotoEnd()
            return nil
        case 26: // 9 key
            DebugLogger.log("9 key pressed - Menu")
            // TODO: Implement menu functionality
            return nil
        case 27: // 0 key (for 10)
            DebugLogger.log("0 key pressed - Quit")
            handleQuitKey()
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
                ScreenView(document: document, contentToDisplay: Messages.quitMessage, displayRows: AppSettings.rows - 2, rowOffset: 1, overlayLayers: .constant([]), overlayOpacities: .constant([:]))
                    .environmentObject(fontManager)
                    .frame(height: CGFloat(AppSettings.rows - 2) * CGFloat(ScreenView.charH))
            } else {
                ScreenView(document: document, displayRows: AppSettings.rows - 2, rowOffset: 1, overlayLayers: $overlayLayers, overlayOpacities: $overlayOpacities)
                    .environmentObject(fontManager)
                    .frame(height: CGFloat(AppSettings.rows - 2) * CGFloat(ScreenView.charH))
                    .onAppear {
                        if document.fileName.isEmpty, document.totalLines == 0 {
                            DebugLogger.log("Skipping loadWelcomeText; using overlay only")
                        }
                        DebugLogger.log("Main content area appeared")
                        if welcomeOverlayId == nil, helpOverlayId == nil, document.fileName.isEmpty {
                            welcomeOverlayId = addOverlay(kind: .welcome)
                            DebugLogger.log("Welcome overlay added (id=\(welcomeOverlayId!))")
                        }
                        installQuitMonitor()
                    }
                    .fileImporter(isPresented: $showingFilePicker,
                                  allowedContentTypes: [UTType.plainText],
                                  allowsMultipleSelection: false,
                                  onCompletion: handleFileImport)
                    .onChange(of: document.fileName) { _, newFileName in
                        if !newFileName.isEmpty {
                            overlayManager.removeHelpOverlay()
                            removeWelcomeOverlayIfPresent()
                        }
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
