//
//  MainContentScreenView.swift
//  harryfan-reader
//
//  Created by @vt887 on 9/28/25.
//

import AppKit
import Foundation
import SwiftUI
import UniformTypeIdentifiers

// Private struct for the main content screen view
struct MainContentScreenView: View {
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

    // Key handler
    @State private var keyHandler: KeyHandler?

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
        let activeOverlay: KeyHandler.ActiveOverlay = switch kind {
        case .welcome: .welcome
        case .help: .help
        case .quit: .quit
        case let .custom(msg):
            if msg == Messages.quitMessage {
                .quit
            } else {
                .custom
            }
        default: .custom
        }
        keyHandler?.setActiveOverlay(activeOverlay)
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
            if overlayLayers.isEmpty { keyHandler?.setActiveOverlay(.none) }
        }
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
        keyHandler?.handleKeyEvent(event)
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
                        // Initialize key handler
                        keyHandler = KeyHandler(document: document,
                                                overlayLayers: overlayLayers,
                                                overlayOpacities: overlayOpacities,
                                                showingFilePicker: showingFilePicker,
                                                addOverlay: addOverlay,
                                                removeOverlay: removeOverlay,
                                                overlayManager: overlayManager,
                                                recentFilesManager: recentFilesManager)
                        keyHandler?.setWelcomeOverlayId(welcomeOverlayId)
                        keyHandler?.setHelpOverlayId(helpOverlayId)
                        keyHandler?.setFileTextOverlayId(fileTextOverlayId)
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
