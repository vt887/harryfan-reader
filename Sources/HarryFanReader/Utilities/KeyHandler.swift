//
//  KeyHandler.swift
//  harryfan-reader
//
//  Created by @vt887 on 10/12/25.
//

import AppKit
import Foundation

// Uses shared ActiveOverlay from Overlays.swift

// Class to handle key events for the main content screen
class KeyHandler {
    private weak var document: TextDocument?
    private var activeOverlay: ActiveOverlay = .none
    private var welcomeOverlayId: UUID?
    private var helpOverlayId: UUID?
    private var searchOverlayId: UUID?
    private var gotoOverlayId: UUID?
    private var menuOverlayId: UUID?
    private var quitOverlayId: UUID?
    private var statsOverlayId: UUID?
    private var libraryOverlayId: UUID?
    private var overlayLayers: [ScreenLayer]
    private var overlayOpacities: [UUID: Double]
    private var showingFilePicker: Bool
    private let addOverlay: (OverlayKind, Double) -> UUID
    private let removeOverlay: (UUID, Double) -> Void
    private let overlayManager: OverlayManager
    private let recentFilesManager: RecentFilesManager

    init(document: TextDocument,
         overlayLayers: [ScreenLayer],
         overlayOpacities: [UUID: Double],
         showingFilePicker: Bool,
         addOverlay: @escaping (OverlayKind, Double) -> UUID,
         removeOverlay: @escaping (UUID, Double) -> Void,
         overlayManager: OverlayManager,
         recentFilesManager: RecentFilesManager)
    {
        self.document = document
        self.overlayLayers = overlayLayers
        self.overlayOpacities = overlayOpacities
        self.showingFilePicker = showingFilePicker
        self.addOverlay = addOverlay
        self.removeOverlay = removeOverlay
        self.overlayManager = overlayManager
        self.recentFilesManager = recentFilesManager
    }

    // Unified quit handling for F10 / Esc
    private func handleQuitKey() {
        guard let document else { return }
        if Settings.shouldShowQuitMessage, !document.shouldShowQuitMessage {
            document.shouldShowQuitMessage = true
            return
        }
        NSApp.terminate(nil)
    }

    // Helper to cancel and remove the quit overlay
    private func cancelQuitOverlay(_ reason: String? = nil) {
        guard let doc = document else { return }
        DebugLogger.log("Quit overlay: \(reason ?? "cancelled"), cancelling quit dialog.")
        doc.shouldShowQuitMessage = false
        activeOverlay = .none
        if let qId = quitOverlayId {
            removeOverlay(qId, 0.25)
            quitOverlayId = nil
        }
        if let wId = welcomeOverlayId {
            removeOverlay(wId, 0.25)
            welcomeOverlayId = nil
        }
        if let hId = helpOverlayId {
            removeOverlay(hId, 0.25)
            helpOverlayId = nil
        }
    }

    // Map ActiveOverlay to OverlayKind (nil for .none)
    private func overlayKind(from active: ActiveOverlay) -> OverlayKind? {
        switch active {
        case .none: nil
        case .welcome: .welcome
        case .help: .help
        case .quit: .quit
        case .about: .about
        case .search: .search
        case .goto: .goto
        case .menu: .menu
        case .library: .library
        case .statistics: .statistics
        }
    }

    // Event handler
    func handleKeyEvent(_ event: NSEvent) -> NSEvent? {
        guard let document else { return event }
        DebugLogger.log("Key pressed: keyCode=\(event.keyCode), characters='\(event.charactersIgnoringModifiers ?? "")', activeOverlay=\(activeOverlay)")

        // If there's an active overlay, consult OverlayPolicies for dismissal
        if activeOverlay != .none, let kind = overlayKind(from: activeOverlay) {
            let policy = OverlayPolicies.allowedActivities(for: kind)

            // Quit overlay special handling
            if kind == .quit {
                if event.charactersIgnoringModifiers?.lowercased() == "y" {
                    DebugLogger.log("Quit overlay: 'y' pressed, terminating app.")
                    NSApp.terminate(nil)
                    return nil
                }
                let isDismissKey = policy.dismissKeyCodes.contains(event.keyCode)
                let isNKey = event.charactersIgnoringModifiers?.lowercased() == "n"
                if policy.allowAnyKeyToDismiss || isDismissKey || isNKey {
                    let reason = isNKey ? "'n' pressed" : (isDismissKey ? "dismiss key pressed" : "any key")
                    cancelQuitOverlay(reason)
                    return nil
                }
                DebugLogger.log("Quit overlay: ignored key.")
                return nil
            }

            // Welcome overlay dismissal
            if kind == .welcome {
                let isDismissKey = policy.dismissKeyCodes.contains(event.keyCode)
                if policy.allowAnyKeyToDismiss || isDismissKey {
                    if let wId = welcomeOverlayId {
                        DebugLogger.log("Welcome overlay: dismissing per policy.")
                        removeOverlay(wId, 0.25)
                        welcomeOverlayId = nil
                        activeOverlay = .none
                    }
                    return nil
                }
                return nil
            }

            // Help overlay dismissal
            if kind == .help {
                let isDismissKey = policy.dismissKeyCodes.contains(event.keyCode)
                if policy.allowAnyKeyToDismiss || isDismissKey {
                    if let hId = helpOverlayId {
                        DebugLogger.log("Help overlay: dismissing per policy.")
                        removeOverlay(hId, 0.25)
                        helpOverlayId = nil
                    }
                    activeOverlay = .none
                    return nil
                }
                DebugLogger.log("Help overlay: ignored key.")
                return nil
            }

            // About overlay dismissal
            if kind == .about {
                let isDismissKey = policy.dismissKeyCodes.contains(event.keyCode)
                if policy.allowAnyKeyToDismiss || isDismissKey {
                    DebugLogger.log("About overlay: dismissing per policy.")
                    if let hId = helpOverlayId { removeOverlay(hId, 0.25); helpOverlayId = nil }
                    if let wId = welcomeOverlayId { removeOverlay(wId, 0.25); welcomeOverlayId = nil }
                    if let qId = quitOverlayId { removeOverlay(qId, 0.25); quitOverlayId = nil }
                    overlayManager.removeAll()
                    activeOverlay = .none
                    return nil
                }
                DebugLogger.log("About overlay: ignored key.")
                return nil
            }

            // Statistics overlay dismissal (explicit handler)
            if kind == .statistics {
                // User reported statistics overlay wasn't dismissing; accept any key to dismiss it.
                DebugLogger.log("Statistics overlay: key pressed keyCode=\(event.keyCode) — dismissing overlay on any key")
                if let sId = statsOverlayId { removeOverlay(sId, 0.25); statsOverlayId = nil }
                overlayManager.removeOverlay(.statistics)
                activeOverlay = .none
                return nil
            }

            // Generic dismissal for overlays (statistics, menu, search, goto)
            // If policy allows dismissal by specific keys or any key, remove the overlay and clear tracked ids
            let isDismissKeyGeneric = policy.dismissKeyCodes.contains(event.keyCode)
            if policy.allowAnyKeyToDismiss || isDismissKeyGeneric {
                switch kind {
                case .statistics:
                    DebugLogger.log("Statistics overlay: dismissing per policy.")
                    if let sId = statsOverlayId { removeOverlay(sId, 0.25); statsOverlayId = nil }
                    overlayManager.removeOverlay(.statistics)
                    activeOverlay = .none
                    return nil
                case .library:
                    DebugLogger.log("Library overlay: dismissing per policy.")
                    if let lId = libraryOverlayId { removeOverlay(lId, 0.25); libraryOverlayId = nil }
                    overlayManager.removeOverlay(.library)
                    activeOverlay = .none
                    return nil
                case .menu:
                    DebugLogger.log("Menu overlay: dismissing per policy.")
                    if let mId = menuOverlayId { removeOverlay(mId, 0.25); menuOverlayId = nil }
                    overlayManager.removeOverlay(.menu)
                    activeOverlay = .none
                    return nil
                case .search:
                    DebugLogger.log("Search overlay: dismissing per policy.")
                    if let sId = searchOverlayId { removeOverlay(sId, 0.25); searchOverlayId = nil }
                    overlayManager.removeOverlay(.search)
                    activeOverlay = .none
                    return nil
                case .goto:
                    DebugLogger.log("Goto overlay: dismissing per policy.")
                    if let gId = gotoOverlayId { removeOverlay(gId, 0.25); gotoOverlayId = nil }
                    overlayManager.removeOverlay(.goto)
                    activeOverlay = .none
                    return nil
                default:
                    break
                }
            }

            // For other overlays, fall through to per-key handlers below
        }

        // F2 toggles word wrap
        if event.keyCode == KeyCode.f2 {
            document.toggleWordWrap()
            DebugLogger.log("Word wrap toggled (keyCode=\(event.keyCode))")
            return nil
        }

        // F1: toggle help
        if event.keyCode == KeyCode.f1 {
            if let hId = helpOverlayId {
                removeOverlay(hId, 0.25)
                helpOverlayId = nil
                DebugLogger.log("Help overlay hidden (keyCode=\(event.keyCode))")
            } else {
                if let wId = welcomeOverlayId { removeOverlay(wId, 0.25); welcomeOverlayId = nil; DebugLogger.log("Welcome overlay removed before showing help") }
                let newId = addOverlay(.help, 0.25)
                helpOverlayId = newId
                activeOverlay = .help
                DebugLogger.log("Help overlay shown (id=\(newId))")
            }
            return nil
        }

        // F4: toggle search
        if event.keyCode == KeyCode.f4 {
            if let sId = searchOverlayId {
                removeOverlay(sId, 0.25)
                searchOverlayId = nil
                DebugLogger.log("Search overlay hidden (keyCode=\(event.keyCode))")
            } else {
                if let wId = welcomeOverlayId { removeOverlay(wId, 0.25); welcomeOverlayId = nil; DebugLogger.log("Welcome overlay removed before showing search") }
                if let qId = quitOverlayId { removeOverlay(qId, 0.25); quitOverlayId = nil }
                let newId = addOverlay(.search, 0.25)
                searchOverlayId = newId
                activeOverlay = .search
                DebugLogger.log("Search overlay shown (id=\(newId))")
            }
            return nil
        }

        // F6: toggle goto
        if event.keyCode == KeyCode.f6 {
            if let gId = gotoOverlayId {
                removeOverlay(gId, 0.25)
                gotoOverlayId = nil
                DebugLogger.log("Goto overlay hidden (keyCode=\(event.keyCode))")
            } else {
                if let wId = welcomeOverlayId { removeOverlay(wId, 0.25); welcomeOverlayId = nil; DebugLogger.log("Welcome overlay removed before showing goto") }
                if let qId = quitOverlayId { removeOverlay(qId, 0.25); quitOverlayId = nil }
                let newId = addOverlay(.goto, 0.25)
                gotoOverlayId = newId
                activeOverlay = .goto
                DebugLogger.log("Goto overlay shown (id=\(newId))")
            }
            return nil
        }

        // F9: toggle menu
        if event.keyCode == KeyCode.f9 {
            if let mId = menuOverlayId {
                removeOverlay(mId, 0.25)
                menuOverlayId = nil
                DebugLogger.log("Menu overlay hidden (keyCode=\(event.keyCode))")
            } else {
                if let wId = welcomeOverlayId { removeOverlay(wId, 0.25); welcomeOverlayId = nil; DebugLogger.log("Welcome overlay removed before showing menu") }
                if let qId = quitOverlayId { removeOverlay(qId, 0.25); quitOverlayId = nil }
                let newId = addOverlay(.menu, 0.25)
                menuOverlayId = newId
                activeOverlay = .menu
                DebugLogger.log("Menu overlay shown (id=\(newId))")
            }
            return nil
        }

        // Switch for other keys
        switch event.keyCode {
        case KeyCode.f10:
            DebugLogger.log("F10 key pressed")
            document.shouldShowQuitMessage = true
            let quitId = addOverlay(.quit, 0.25)
            quitOverlayId = quitId
            activeOverlay = .quit
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

        case 18: // 1 key
            DebugLogger.log("1 key pressed - Help")
            if let hId = helpOverlayId {
                removeOverlay(hId, 0.25)
                helpOverlayId = nil
                DebugLogger.log("Help overlay hidden")
            } else {
                if let wId = welcomeOverlayId { removeOverlay(wId, 0.25); welcomeOverlayId = nil }
                if let qId = quitOverlayId { removeOverlay(qId, 0.25); quitOverlayId = nil }
                let newId = addOverlay(.help, 0.25)
                helpOverlayId = newId
                activeOverlay = .help
                DebugLogger.log("Help overlay shown")
            }
            return nil

        default:
            return event
        }
    }

    // Update overlay IDs (used by the view to inform handler of tracked ids)
    func setWelcomeOverlayId(_ id: UUID?) { welcomeOverlayId = id }
    func setHelpOverlayId(_ id: UUID?) { helpOverlayId = id }
    func setSearchOverlayId(_ id: UUID?) { searchOverlayId = id }
    func setGotoOverlayId(_ id: UUID?) { gotoOverlayId = id }
    func setMenuOverlayId(_ id: UUID?) { menuOverlayId = id }
    func setQuitOverlayId(_ id: UUID?) { quitOverlayId = id }
    func setStatsOverlayId(_ id: UUID?) { statsOverlayId = id }
    func setLibraryOverlayId(_ id: UUID?) { libraryOverlayId = id }
    func setActiveOverlay(_ overlay: ActiveOverlay) { activeOverlay = overlay }
}
