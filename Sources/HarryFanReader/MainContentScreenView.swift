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
    @State private var quitOverlayId: UUID? = nil // quit overlay tracking
    // Track overlay kinds received from OverlayManager to react to programmatic changes
    @State private var observedOverlayKinds: [OverlayKind] = []

    // Key handler
    @State private var keyHandler: KeyHandler?

    private func removeWelcomeOverlayIfPresent(fadeDuration: Double = 0.25, force: Bool = false) {
        // By default do not remove the welcome overlay automatically.
        // Callers that intend to remove it (e.g. when a user opens a file)
        // should pass `force: true`.
        guard force else {
            DebugLogger.log("removeWelcomeOverlayIfPresent called without force — skipping auto removal")
            return
        }
        if let wId = welcomeOverlayId {
            removeOverlay(id: wId, fadeDuration: fadeDuration)
            welcomeOverlayId = nil
            DebugLogger.log("Welcome overlay removed")
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
        // Set activeOverlay based on kind (no per-kind id tracking here)
        let activeOverlay: ActiveOverlay = switch kind {
        case .welcome: .welcome
        case .help: .help
        case .quit: .quit
        case .about: .about
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
        // User-initiated file import: explicitly remove welcome overlay
        removeWelcomeOverlayIfPresent(force: true)
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
            // Always render the screen with overlayLayers and let overlays (welcome/help/about/quit)
            // be displayed using the OverlayFactory (centered). This aligns the quit overlay
            // with the welcome overlay which is also produced by the OverlayFactory.
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
                    // set handler's known overlay ids
                    keyHandler?.setWelcomeOverlayId(welcomeOverlayId)
                    keyHandler?.setHelpOverlayId(helpOverlayId)
                    keyHandler?.setQuitOverlayId(quitOverlayId)
                    // If we've just created a welcome overlay, mark it as the active overlay
                    // and make it temporarily non-dismissable to avoid accidental dismissal
                    // from synthetic or startup key events. Enable dismissal after a short delay.
                    if welcomeOverlayId != nil {
                        keyHandler?.setActiveOverlay(.welcome)
                    }
                    // If OverlayManager already contains .about (added earlier by AppDelegate), mirror it here
                    if overlayManager.overlays.contains(.about) {
                        DebugLogger.log("MainContentScreenView.onAppear: overlayManager already contains .about — ensuring about overlay is shown")
                        let aboutFirstLine = Messages.aboutMessage.split(separator: "\n", omittingEmptySubsequences: true).first.map { String($0).trimmingCharacters(in: .whitespaces) } ?? ""
                        let alreadyShowing = overlayLayers.contains { layer in
                            guard !aboutFirstLine.isEmpty else { return false }
                            let rows = layer.grid.count
                            let cols = layer.grid.first?.count ?? 0
                            for r in 0 ..< rows {
                                var rowStr = ""
                                for c in 0 ..< cols {
                                    rowStr.append(layer[r, c].char)
                                }
                                if rowStr.trimmingCharacters(in: .whitespaces).contains(aboutFirstLine) { return true }
                            }
                            return false
                        }
                        if !alreadyShowing {
                            _ = addOverlay(kind: .about)
                        }
                    }
                }
                .fileImporter(isPresented: $showingFilePicker,
                              allowedContentTypes: [UTType.plainText],
                              allowsMultipleSelection: false,
                              onCompletion: handleFileImport)
                .onChange(of: document.fileName) { _, newFileName in
                    if !newFileName.isEmpty {
                        overlayManager.removeHelpOverlay()
                        // File name changed as a result of user action — explicitly remove welcome overlay
                        removeWelcomeOverlayIfPresent(force: true)
                    }
                }
                // Listen for the showAboutOverlay notification and add the about overlay in this view
                .onReceive(NotificationCenter.default.publisher(for: .showAboutOverlay)) { _ in
                    DebugLogger.log("MainContentScreenView: received showAboutOverlay notification — adding about overlay")
                    // Remove welcome/help overlays first and then add about overlay
                    overlayManager.removeHelpOverlay()
                    // Intentionally not removing the welcome overlay here; it should be
                    // dismissed only by explicit user actions (file open) or when a
                    // caller passes `force: true`.

                    // If about overlay is already present in overlayLayers, skip adding
                    let aboutFirstLine = Messages.aboutMessage.split(separator: "\n", omittingEmptySubsequences: true).first.map { String($0).trimmingCharacters(in: .whitespaces) } ?? ""
                    let alreadyShowing = overlayLayers.contains { layer in
                        guard !aboutFirstLine.isEmpty else { return false }
                        let rows = layer.grid.count
                        let cols = layer.grid.first?.count ?? 0
                        for r in 0 ..< rows {
                            var rowStr = ""
                            for c in 0 ..< cols {
                                rowStr.append(layer[r, c].char)
                            }
                            if rowStr.trimmingCharacters(in: .whitespaces).contains(aboutFirstLine) { return true }
                        }
                        return false
                    }
                    if !alreadyShowing {
                        _ = addOverlay(kind: .about)
                    } else {
                        DebugLogger.log("About overlay already showing; skipping add.")
                    }
                }
                // React to overlays added to OverlayManager (programmatic additions elsewhere)
                .onReceive(overlayManager.$overlays) { newKinds in
                    // Determine newly added kinds
                    let added = newKinds.filter { !observedOverlayKinds.contains($0) }
                    observedOverlayKinds = newKinds
                    if added.contains(.about) {
                        DebugLogger.log("MainContentScreenView: detected .about added to OverlayManager — adding about overlay")
                        // Mirror behavior: remove help/welcome and add about overlay if not already present
                        overlayManager.removeHelpOverlay()
                        // Intentionally do not auto-remove the welcome overlay here.

                        let aboutFirstLine = Messages.aboutMessage.split(separator: "\n", omittingEmptySubsequences: true).first.map { String($0).trimmingCharacters(in: .whitespaces) } ?? ""
                        let alreadyShowing = overlayLayers.contains { layer in
                            guard !aboutFirstLine.isEmpty else { return false }
                            let rows = layer.grid.count
                            let cols = layer.grid.first?.count ?? 0
                            for r in 0 ..< rows {
                                var rowStr = ""
                                for c in 0 ..< cols {
                                    rowStr.append(layer[r, c].char)
                                }
                                if rowStr.trimmingCharacters(in: .whitespaces).contains(aboutFirstLine) { return true }
                            }
                            return false
                        }
                        if !alreadyShowing {
                            _ = addOverlay(kind: .about)
                        }
                    }
                }
                // React to changes in the document.shouldShowQuitMessage flag and show/hide a centered quit overlay
                .onChange(of: document.shouldShowQuitMessage) { _, showQuit in
                    let quitFirstLine = Messages.quitMessage.split(separator: "\n", omittingEmptySubsequences: true).first.map { String($0).trimmingCharacters(in: .whitespaces) } ?? ""
                    let alreadyShowingQuit = overlayLayers.contains { layer in
                        guard !quitFirstLine.isEmpty else { return false }
                        let rows = layer.grid.count
                        let cols = layer.grid.first?.count ?? 0
                        for r in 0 ..< rows {
                            var rowStr = ""
                            for c in 0 ..< cols {
                                rowStr.append(layer[r, c].char)
                            }
                            if rowStr.trimmingCharacters(in: .whitespaces).contains(quitFirstLine) { return true }
                        }
                        return false
                    }
                    if showQuit {
                        overlayManager.removeHelpOverlay()
                        // Do not remove the welcome overlay automatically when showing quit.
                        if !alreadyShowingQuit {
                            let qid = addOverlay(kind: .quit)
                            quitOverlayId = qid
                            keyHandler?.setActiveOverlay(.quit)
                            DebugLogger.log("Quit overlay shown (id=\(qid))")
                        }
                    } else {
                        if let qId = quitOverlayId {
                            removeOverlay(id: qId)
                            quitOverlayId = nil
                        }
                    }
                }
        }
        .onAppear { installQuitMonitor() }
        .onDisappear { removeQuitMonitor() }
    }
}
