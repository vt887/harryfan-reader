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
    @State private var searchOverlayId: UUID? = nil // search overlay tracking
    @State private var menuOverlayId: UUID? = nil // menu overlay tracking
    @State private var gotoOverlayId: UUID? = nil // goto overlay tracking
    @State private var quitOverlayId: UUID? = nil // quit overlay tracking
    // Track overlay kinds received from OverlayManager to react to programmatic changes
    @State private var observedOverlayKinds: [OverlayKind] = []

    // Key handler
    @State private var keyHandler: KeyHandler?

    private func removeWelcomeOverlayIfPresent(fadeDuration: Double = 0, force: Bool = false) {
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
        let layer = OverlayFactory.make(kind: kind, rows: Settings.rows - 2, cols: Settings.cols)
        let id = layer.id
        DebugLogger.log("addOverlay: kind=\(kind) id=\(id)")
        overlayLayers.append(layer)

        overlayOpacities[id] = 0.0
        withAnimation(.easeInOut(duration: fadeDuration)) {
            overlayOpacities[id] = 1.0
        }
        // Set activeOverlay based on kind using centralized mapping
        keyHandler?.setActiveOverlay(kind.activeOverlay)
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
            // If we removed a tracked overlay id, clear it and inform keyHandler
            if id == helpOverlayId {
                helpOverlayId = nil
                keyHandler?.setHelpOverlayId(nil)
            }
            if id == welcomeOverlayId {
                welcomeOverlayId = nil
                keyHandler?.setWelcomeOverlayId(nil)
            }
            if id == searchOverlayId {
                searchOverlayId = nil
                keyHandler?.setSearchOverlayId(nil)
            }
            if id == menuOverlayId {
                menuOverlayId = nil
                keyHandler?.setMenuOverlayId(nil)
            }
            if id == gotoOverlayId {
                gotoOverlayId = nil
                keyHandler?.setGotoOverlayId(nil)
            }
            if id == quitOverlayId {
                quitOverlayId = nil
                keyHandler?.setQuitOverlayId(nil)
            }
            // Reset activeOverlay if no overlays left
            if overlayLayers.isEmpty { keyHandler?.setActiveOverlay(.none) }
        }
    }

    // Unified quit handling for F10 / Esc
    private func handleQuitKey() {
        if Settings.shouldShowQuitMessage, !document.shouldShowQuitMessage {
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
            ScreenView(document: document, displayRows: Settings.rows - 2, rowOffset: 1, overlayLayers: $overlayLayers, overlayOpacities: $overlayOpacities)
                .environmentObject(fontManager)
                .frame(height: CGFloat(Settings.rows - 2) * CGFloat(ScreenView.charH))
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
                    keyHandler?.setSearchOverlayId(searchOverlayId)
                    keyHandler?.setMenuOverlayId(menuOverlayId)
                    keyHandler?.setGotoOverlayId(gotoOverlayId)
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
                // Listen for the toggleHelpOverlay notification and toggle the help overlay
                .onReceive(NotificationCenter.default.publisher(for: .toggleHelpOverlay)) { _ in
                    DebugLogger.log("MainContentScreenView: received toggleHelpOverlay notification")
                    // If we have a tracked help overlay id, remove it (toggle off)
                    if let hid = helpOverlayId {
                        DebugLogger.log("MainContentScreenView: hiding tracked help overlay id=\(hid)")
                        removeOverlay(id: hid)
                        // helpOverlayId will be cleared in removeOverlay's completion
                        return
                    }

                    // Otherwise, check if a help overlay (by first line) exists in overlayLayers
                    let helpFirstLine = Messages.helpMessage.split(separator: "\n", omittingEmptySubsequences: true).first.map { String($0).trimmingCharacters(in: .whitespaces) } ?? ""
                    if !helpFirstLine.isEmpty {
                        if let existing = overlayLayers.first(where: { layer in
                            let rows = layer.grid.count
                            let cols = layer.grid.first?.count ?? 0
                            for r in 0 ..< rows {
                                var rowStr = ""
                                for c in 0 ..< cols {
                                    rowStr.append(layer[r, c].char)
                                }
                                if rowStr.trimmingCharacters(in: .whitespaces).contains(helpFirstLine) { return true }
                            }
                            return false
                        }) {
                            DebugLogger.log("MainContentScreenView: hiding existing help overlay id=\(existing.id)")
                            removeOverlay(id: existing.id)
                            return
                        }
                    }

                    // No help overlay visible: show it
                    let hid = addOverlay(kind: .help)
                    helpOverlayId = hid
                    keyHandler?.setHelpOverlayId(hid)
                    keyHandler?.setActiveOverlay(.help)
                    DebugLogger.log("Help overlay shown (id=\(hid))")
                }
                // React to overlays added to OverlayManager (programmatic additions elsewhere)
                .onReceive(overlayManager.$overlays) { newKinds in
                    // Determine newly added and removed kinds (compare to previous observedOverlayKinds)
                    let added = newKinds.filter { !observedOverlayKinds.contains($0) }
                    observedOverlayKinds = newKinds

                    if added.contains(.about) {
                        DebugLogger.log("MainContentScreenView: detected .about added to OverlayManager — adding about overlay")
                        // Mirror behavior: add about overlay if not already present
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

                    if added.contains(.statistics) {
                        DebugLogger.log("MainContentScreenView: detected .statistics added to OverlayManager — adding statistics overlay (live)")
                        // If a statistics overlay is already present, skip adding
                        let alreadyShowing = overlayLayers.contains { $0.overlayKind == .statistics }
                        if !alreadyShowing {
                            // Create a live statistics layer using current document data
                            var statsLayer = OverlayFactory.makeStatisticsOverlay(document: document, rows: Settings.rows - 2, cols: Settings.cols)
                            statsLayer.overlayKind = .statistics
                            let id = statsLayer.id
                            overlayLayers.append(statsLayer)
                            overlayOpacities[id] = 0.0
                            withAnimation(.easeInOut(duration: 0.25)) {
                                overlayOpacities[id] = 1.0
                            }
                            keyHandler?.setActiveOverlay(.statistics)
                            DebugLogger.log("Statistics overlay shown (id=\(id))")
                        }
                    }
                }
                // React to requests to show the quit overlay posted by AppDelegate
                .onReceive(NotificationCenter.default.publisher(for: .showQuitOverlay)) { _ in
                    DebugLogger.log("MainContentScreenView: received showQuitOverlay notification — showing quit overlay")
                    document.shouldShowQuitMessage = true
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
