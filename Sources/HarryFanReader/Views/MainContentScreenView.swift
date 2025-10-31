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
    @State private var welcomeOverlayId: UUID? = nil // welcome overlay tracking
    @State private var helpOverlayId: UUID? = nil // help overlay tracking
    @State private var searchOverlayId: UUID? = nil // search overlay tracking
    @State private var menuOverlayId: UUID? = nil // menu overlay tracking
    @State private var gotoOverlayId: UUID? = nil // goto overlay tracking
    @State private var quitOverlayId: UUID? = nil // quit overlay tracking
    @State private var statsOverlayId: UUID? = nil // statistics overlay tracking
    @State private var libraryOverlayId: UUID? = nil // library overlay tracking
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

    // Add a pre-built ScreenLayer (used to insert document-aware overlays like Statistics)
    private func addCustomOverlay(_ layer: ScreenLayer, fadeDuration: Double = 0.25) -> UUID {
        let id = layer.id
        DebugLogger.log("addCustomOverlay: kind=\(String(describing: layer.overlayKind)) id=\(id)")
        overlayLayers.append(layer)
        overlayOpacities[id] = 0.0
        withAnimation(.easeInOut(duration: fadeDuration)) {
            overlayOpacities[id] = 1.0
        }
        if let kind = layer.overlayKind {
            keyHandler?.setActiveOverlay(kind.activeOverlay)
            switch kind {
            case .statistics: statsOverlayId = id; keyHandler?.setStatsOverlayId(id)
            case .library: libraryOverlayId = id; keyHandler?.setLibraryOverlayId(id)
            default: break
            }
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
            if id == statsOverlayId {
                statsOverlayId = nil
                keyHandler?.setStatsOverlayId(nil)
            }
            if id == libraryOverlayId {
                libraryOverlayId = nil
                keyHandler?.setLibraryOverlayId(nil)
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

    // Keep the body very small to help the Swift compiler type-check quickly.
    private var screenContent: some View {
        ScreenView(document: document, displayRows: Settings.rows - 2, rowOffset: 1, overlayLayers: $overlayLayers, overlayOpacities: $overlayOpacities)
            .environmentObject(fontManager)
            .frame(height: Settings.contentSize(rows: Settings.rows - 2, cols: ScreenView.cols).height)
    }

    var body: some View {
        Group {
            screenContent
                .onAppear(perform: onAppearAction)
                .fileImporter(isPresented: $showingFilePicker,
                              allowedContentTypes: [UTType.plainText],
                              allowsMultipleSelection: false,
                              onCompletion: handleFileImport)
                .onChange(of: document.fileName) { _, newFileName in
                    handleDocumentFileNameChange(newFileName)
                }
                .onReceive(NotificationCenter.default.publisher(for: .showAboutOverlay), perform: handleShowAboutNotification)
                .onReceive(NotificationCenter.default.publisher(for: .toggleHelpOverlay), perform: handleToggleHelpNotification)
                .onReceive(overlayManager.$overlays, perform: handleOverlayManagerChange)
                .onReceive(NotificationCenter.default.publisher(for: .showQuitOverlay), perform: handleShowQuitOverlay)
                .onChange(of: document.shouldShowQuitMessage) { _, newValue in
                    handleDocumentShouldShowQuitChange(newValue)
                }
        }
        .onAppear { installQuitMonitor() }
        .onDisappear { removeQuitMonitor() }
    }

    // MARK: - Helper methods extracted from body to simplify type-checking

    private func onAppearAction() {
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
        // Ensure keyHandler knows about any existing library overlay id
        keyHandler?.setLibraryOverlayId(libraryOverlayId)
        // set handler's known overlay ids
        keyHandler?.setWelcomeOverlayId(welcomeOverlayId)
        keyHandler?.setHelpOverlayId(helpOverlayId)
        keyHandler?.setSearchOverlayId(searchOverlayId)
        keyHandler?.setMenuOverlayId(menuOverlayId)
        keyHandler?.setGotoOverlayId(gotoOverlayId)
        keyHandler?.setQuitOverlayId(quitOverlayId)
        // Inform keyHandler about statistics overlay if it already exists
        if let sId = statsOverlayId {
            keyHandler?.setStatsOverlayId(sId)
            keyHandler?.setActiveOverlay(.statistics)
        }
        if welcomeOverlayId != nil { keyHandler?.setActiveOverlay(.welcome) }
        // Mirror any .about overlay present in OverlayManager
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
                    if rowStr.trimmingCharacters(in: .whitespaces).contains(aboutFirstLine) {
                        return true
                    }
                }
                return false
            }
            if !alreadyShowing { _ = addOverlay(kind: .about) }
        }
    }

    private func handleDocumentFileNameChange(_ newFileName: String) {
        if !newFileName.isEmpty {
            overlayManager.removeHelpOverlay()
            removeWelcomeOverlayIfPresent(force: true)
        }
    }

    private func handleShowAboutNotification(_: Notification) {
        DebugLogger.log("MainContentScreenView: received showAboutOverlay notification — adding about overlay")
        overlayManager.removeHelpOverlay()
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
                if rowStr.trimmingCharacters(in: .whitespaces).contains(aboutFirstLine) {
                    return true
                }
            }
            return false
        }
        if !alreadyShowing { _ = addOverlay(kind: .about) }
    }

    private func handleToggleHelpNotification(_: Notification) {
        DebugLogger.log("MainContentScreenView: received toggleHelpOverlay notification")
        if let hid = helpOverlayId { DebugLogger.log("MainContentScreenView: hiding tracked help overlay id=\(hid)"); removeOverlay(id: hid); return }
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
        let hid = addOverlay(kind: .help)
        helpOverlayId = hid
        keyHandler?.setHelpOverlayId(hid)
        keyHandler?.setActiveOverlay(.help)
        DebugLogger.log("Help overlay shown (id=\(hid))")
    }

    private func handleOverlayManagerChange(_ newKinds: [OverlayKind]) {
        let added = newKinds.filter { !observedOverlayKinds.contains($0) }
        observedOverlayKinds = newKinds
        if added.contains(.about) {
            DebugLogger.log("MainContentScreenView: detected .about added to OverlayManager — adding about overlay")
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
            if !alreadyShowing { _ = addOverlay(kind: .about) }
        }
        if added.contains(.statistics) {
            DebugLogger.log("MainContentScreenView: detected .statistics added to OverlayManager — adding statistics overlay (live)")
            let alreadyShowing = overlayLayers.contains { $0.overlayKind == .statistics }
            if !alreadyShowing {
                var statsLayer = OverlayFactory.makeStatisticsOverlay(document: document, rows: Settings.rows - 2, cols: Settings.cols)
                statsLayer.overlayKind = .statistics
                let id = addCustomOverlay(statsLayer)
                statsOverlayId = id
                DebugLogger.log("Statistics overlay shown (id=\(id))")
            }
        }
        if added.contains(.library) {
            DebugLogger.log("MainContentScreenView: detected .library added to OverlayManager — adding library overlay")
            let alreadyShowing = overlayLayers.contains { $0.overlayKind == .library }
            if !alreadyShowing {
                let libLayer = OverlayFactory.makeLibraryOverlay(rows: Settings.rows - 2, cols: Settings.cols)
                var layer = libLayer
                layer.overlayKind = .library
                let id = addCustomOverlay(layer)
                libraryOverlayId = id
                DebugLogger.log("Library overlay shown (id=\(id))")
            }
        }
    }

    private func handleShowQuitOverlay(_: Notification) {
        DebugLogger.log("MainContentScreenView: received showQuitOverlay notification — showing quit overlay")
        document.shouldShowQuitMessage = true
    }

    private func handleDocumentShouldShowQuitChange(_ showQuit: Bool) {
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
            if !alreadyShowingQuit {
                let qid = addOverlay(kind: .quit)
                quitOverlayId = qid
                keyHandler?.setActiveOverlay(.quit)
                DebugLogger.log("Quit overlay shown (id=\(qid))")
            }
        } else {
            if let qId = quitOverlayId { removeOverlay(id: qId); quitOverlayId = nil }
        }
    }
}
