//
//  KeyHandler.swift
//  harryfan-reader
//
//  Created by @vt887 on 10/12/25.
//

import AppKit
import Foundation

// Struct to group overlay-related context for KeyHandler
struct OverlayContext {
    var overlayLayers: [ScreenLayer]
    var overlayOpacities: [UUID: Double]
    var showingFilePicker: Bool
    let addOverlay: (OverlayKind, Double) -> UUID
    let removeOverlay: (UUID, Double) -> Void
}

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
    private var overlayContext: OverlayContext
    private let overlayManager: OverlayManager
    private let recentFilesManager: RecentFilesManager

    // Initialize KeyHandler with provided dependencies
    init(document: TextDocument,
         overlayContext: OverlayContext,
         overlayManager: OverlayManager,
         recentFilesManager: RecentFilesManager)
    {
        self.document = document
        self.overlayContext = overlayContext
        self.overlayManager = overlayManager
        self.recentFilesManager = recentFilesManager
    }

    // Convenience initializer retained for compatibility with older call sites/tests.
    convenience init(document: TextDocument,
                     overlayLayers: [ScreenLayer],
                     overlayOpacities: [UUID: Double],
                     showingFilePicker: Bool,
                     addOverlay: @escaping (OverlayKind, Double) -> UUID,
                     removeOverlay: @escaping (UUID, Double) -> Void,
                     overlayManager: OverlayManager,
                     recentFilesManager: RecentFilesManager)
    {
        let ctx = OverlayContext(overlayLayers: overlayLayers,
                                 overlayOpacities: overlayOpacities,
                                 showingFilePicker: showingFilePicker,
                                 addOverlay: addOverlay,
                                 removeOverlay: removeOverlay)
        self.init(document: document, overlayContext: ctx, overlayManager: overlayManager, recentFilesManager: recentFilesManager)
    }

    // Cancel and remove any active quit/welcome/help overlays
    private func cancelQuitOverlay(_ reason: String? = nil) {
        guard let doc = document else { return }
        DebugLogger.log("Quit overlay: \(reason ?? "cancelled"), cancelling quit dialog.")
        doc.shouldShowQuitMessage = false
        activeOverlay = .none
        if let qId = quitOverlayId {
            overlayContext.removeOverlay(qId, Settings.overlayAnimationDuration)
            quitOverlayId = nil
        }
        if let wId = welcomeOverlayId {
            overlayContext.removeOverlay(wId, Settings.overlayAnimationDuration)
            welcomeOverlayId = nil
        }
        if let hId = helpOverlayId {
            overlayContext.removeOverlay(hId, Settings.overlayAnimationDuration)
            helpOverlayId = nil
        }
    }

    // Map an ActiveOverlay value to its corresponding OverlayKind if any
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

    // Main key event handler for the application; returns nil if event was consumed
    func handleKeyEvent(_ event: NSEvent) -> NSEvent? {
        guard let document else { return event }
        DebugLogger.log("Key pressed: keyCode=\(event.keyCode), characters='\(event.charactersIgnoringModifiers ?? "")', activeOverlay=\(activeOverlay)")

        // If there's an active overlay, consult OverlayPolicies for dismissal or special handling
        if activeOverlay != .none, let kind = overlayKind(from: activeOverlay), handleActiveOverlayKey(kind: kind, event: event) {
            // consumed by overlay handling
            return nil
        }
        // not consumed -> fall through to global handlers

        // Global/application-level keys
        if event.keyCode == KeyCode.f2 {
            document.toggleWordWrap()
            DebugLogger.log("Word wrap toggled (keyCode=\(event.keyCode))")
            return nil
        }

        if event.keyCode == KeyCode.f1 {
            toggleHelpOverlay()
            return nil
        }

        if event.keyCode == KeyCode.f4 {
            toggleSearchOverlay()
            return nil
        }

        if event.keyCode == KeyCode.f6 {
            toggleGotoOverlay()
            return nil
        }

        if event.keyCode == KeyCode.f9 {
            toggleMenuOverlay()
            return nil
        }

        switch event.keyCode {
        case KeyCode.f10:
            DebugLogger.log("F10 key pressed")
            document.shouldShowQuitMessage = true
            let quitId = overlayContext.addOverlay(.quit, Settings.overlayAnimationDuration)
            quitOverlayId = quitId
            activeOverlay = .quit
            DebugLogger.log("Quit overlay shown (id=\(quitId))")
            return nil

        case KeyCode.f3:
            DebugLogger.log("F3 key pressed - opening file picker")
            overlayContext.showingFilePicker = true
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
            toggleHelpOverlay()
            return nil

        default:
            return event
        }
    }

    // Handle keys for an active overlay; returns true if the key was consumed
    private func handleActiveOverlayKey(kind: OverlayKind, event: NSEvent) -> Bool {
        let policy = OverlayPolicies.allowedActivities(for: kind)

        switch kind {
        case .quit:
            return handleQuitOverlayKey(event: event, policy: policy)
        case .welcome:
            return handleSimpleDismissOverlayId(overlayId: &welcomeOverlayId, logPrefix: "Welcome overlay", event: event, policy: policy)
        case .help:
            return handleSimpleDismissOverlayId(overlayId: &helpOverlayId, logPrefix: "Help overlay", event: event, policy: policy)
        case .about:
            return handleAboutOverlayKey(event: event, policy: policy)
        case .statistics:
            // statistics explicitly dismisses on any key
            DebugLogger.log("Statistics overlay: key pressed keyCode=\(event.keyCode) — dismissing overlay on any key")
            if let sId = statsOverlayId {
                overlayContext.removeOverlay(sId, Settings.overlayAnimationDuration)
                statsOverlayId = nil
            }
            overlayManager.removeOverlay(.statistics)
            activeOverlay = .none
            return true
        case .library:
            return handleGenericDismiss(kind: OverlayKind.library, overlayId: &libraryOverlayId, event: event, policy: policy)
        case .menu:
            return handleGenericDismiss(kind: OverlayKind.menu, overlayId: &menuOverlayId, event: event, policy: policy)
        case .search:
            return handleGenericDismiss(kind: OverlayKind.search, overlayId: &searchOverlayId, event: event, policy: policy)
        case .goto:
            return handleGenericDismiss(kind: OverlayKind.goto, overlayId: &gotoOverlayId, event: event, policy: policy)
        }
    }

    // Handle quit overlay-specific keys (confirm/deny/dismiss)
    private func handleQuitOverlayKey(event: NSEvent, policy: OverlayAllowedActivities) -> Bool {
        if event.charactersIgnoringModifiers?.lowercased() == "y" {
            DebugLogger.log("Quit overlay: 'y' pressed, terminating app.")
            NSApp.terminate(nil)
            return true
        }
        let isDismissKey = policy.dismissKeyCodes.contains(event.keyCode)
        let isNKey = event.charactersIgnoringModifiers?.lowercased() == "n"
        if policy.allowAnyKeyToDismiss || isDismissKey || isNKey {
            let reason: String
            if isNKey {
                reason = "'n' pressed"
            } else if isDismissKey {
                reason = "dismiss key pressed"
            } else {
                reason = "any key"
            }
            cancelQuitOverlay(reason)
            return true
        }
        DebugLogger.log("Quit overlay: ignored key.")
        return true // consumed (ignored)
    }

    // Handle simple overlays that dismiss on allowed keys
    private func handleSimpleDismissOverlayId(overlayId: inout UUID?, logPrefix: String, event: NSEvent, policy: OverlayAllowedActivities) -> Bool {
        let isDismissKey = policy.dismissKeyCodes.contains(event.keyCode)
        if policy.allowAnyKeyToDismiss || isDismissKey {
            if let id = overlayId {
                DebugLogger.log("\(logPrefix): dismissing per policy.")
                overlayContext.removeOverlay(id, Settings.overlayAnimationDuration)
                overlayId = nil
            }
            activeOverlay = .none
            return true
        }
        // Not dismissed; consume the key (original code ignored non-dismiss keys)
        DebugLogger.log("\(logPrefix): ignored key.")
        return true
    }

    // Handle About overlay dismissal rules and cleanup
    private func handleAboutOverlayKey(event: NSEvent, policy: OverlayAllowedActivities) -> Bool {
        let isDismissKey = policy.dismissKeyCodes.contains(event.keyCode)
        if policy.allowAnyKeyToDismiss || isDismissKey {
            DebugLogger.log("About overlay: dismissing per policy.")
            if let hId = helpOverlayId {
                overlayContext.removeOverlay(hId, Settings.overlayAnimationDuration)
                helpOverlayId = nil
            }
            if let wId = welcomeOverlayId {
                overlayContext.removeOverlay(wId, Settings.overlayAnimationDuration)
                welcomeOverlayId = nil
            }
            if let qId = quitOverlayId {
                overlayContext.removeOverlay(qId, Settings.overlayAnimationDuration)
                quitOverlayId = nil
            }
            overlayManager.removeAll()
            activeOverlay = .none
            return true
        }
        DebugLogger.log("About overlay: ignored key.")
        return true
    }

    // Generic dismiss handler for overlays that follow the same policy rules
    private func handleGenericDismiss(kind: OverlayKind, overlayId: inout UUID?, event: NSEvent, policy: OverlayAllowedActivities) -> Bool {
        let isDismissKey = policy.dismissKeyCodes.contains(event.keyCode)
        if policy.allowAnyKeyToDismiss || isDismissKey {
            DebugLogger.log("\(kind) overlay: dismissing per policy.")
            if let id = overlayId {
                overlayContext.removeOverlay(id, Settings.overlayAnimationDuration)
                overlayId = nil
            }
            overlayManager.removeOverlay(kind)
            activeOverlay = .none
            return true
        }
        // Not dismissed -> allow fallthrough to global handlers
        return false
    }

    // Toggle the Help overlay on/off
    private func toggleHelpOverlay() {
        if let hId = helpOverlayId {
            overlayContext.removeOverlay(hId, Settings.overlayAnimationDuration)
            helpOverlayId = nil
            DebugLogger.log("Help overlay hidden")
        } else {
            if let wId = welcomeOverlayId {
                overlayContext.removeOverlay(wId, Settings.overlayAnimationDuration)
                welcomeOverlayId = nil
                DebugLogger.log("Welcome overlay removed before showing help")
            }
            let newId = overlayContext.addOverlay(.help, Settings.overlayAnimationDuration)
            helpOverlayId = newId
            activeOverlay = .help
            DebugLogger.log("Help overlay shown (id=\(newId))")
        }
    }

    // Toggle the Search overlay on/off
    private func toggleSearchOverlay() {
        if let sId = searchOverlayId {
            overlayContext.removeOverlay(sId, Settings.overlayAnimationDuration)
            searchOverlayId = nil
            DebugLogger.log("Search overlay hidden (key)")
        } else {
            if let wId = welcomeOverlayId {
                overlayContext.removeOverlay(wId, Settings.overlayAnimationDuration)
                welcomeOverlayId = nil
                DebugLogger.log("Welcome overlay removed before showing search")
            }
            if let qId = quitOverlayId {
                overlayContext.removeOverlay(qId, Settings.overlayAnimationDuration)
                quitOverlayId = nil
            }
            let newId = overlayContext.addOverlay(.search, Settings.overlayAnimationDuration)
            searchOverlayId = newId
            activeOverlay = .search
            DebugLogger.log("Search overlay shown (id=\(newId))")
        }
    }

    // Toggle the Goto overlay on/off
    private func toggleGotoOverlay() {
        if let gId = gotoOverlayId {
            overlayContext.removeOverlay(gId, Settings.overlayAnimationDuration)
            gotoOverlayId = nil
            DebugLogger.log("Goto overlay hidden")
        } else {
            if let wId = welcomeOverlayId {
                overlayContext.removeOverlay(wId, Settings.overlayAnimationDuration)
                welcomeOverlayId = nil
                DebugLogger.log("Welcome overlay removed before showing goto")
            }
            if let qId = quitOverlayId {
                overlayContext.removeOverlay(qId, Settings.overlayAnimationDuration)
                quitOverlayId = nil
            }
            let newId = overlayContext.addOverlay(.goto, Settings.overlayAnimationDuration)
            gotoOverlayId = newId
            activeOverlay = .goto
            DebugLogger.log("Goto overlay shown (id=\(newId))")
        }
    }

    // Toggle the Menu overlay on/off
    private func toggleMenuOverlay() {
        if let mId = menuOverlayId {
            overlayContext.removeOverlay(mId, Settings.overlayAnimationDuration)
            menuOverlayId = nil
            DebugLogger.log("Menu overlay hidden (key)")
        } else {
            if let wId = welcomeOverlayId {
                overlayContext.removeOverlay(wId, Settings.overlayAnimationDuration)
                welcomeOverlayId = nil
                DebugLogger.log("Welcome overlay removed before showing menu")
            }
            if let qId = quitOverlayId {
                overlayContext.removeOverlay(qId, Settings.overlayAnimationDuration)
                quitOverlayId = nil
            }
            let newId = overlayContext.addOverlay(.menu, Settings.overlayAnimationDuration)
            menuOverlayId = newId
            activeOverlay = .menu
            DebugLogger.log("Menu overlay shown (id=\(newId))")
        }
    }

    // Update welcome overlay id
    func setWelcomeOverlayId(_ id: UUID?) {
        welcomeOverlayId = id
    }
    // Update help overlay id
    func setHelpOverlayId(_ id: UUID?) {
        helpOverlayId = id
    }
    // Update search overlay id
    func setSearchOverlayId(_ id: UUID?) {
        searchOverlayId = id
    }
    // Update goto overlay id
    func setGotoOverlayId(_ id: UUID?) {
        gotoOverlayId = id
    }
    // Update menu overlay id
    func setMenuOverlayId(_ id: UUID?) {
        menuOverlayId = id
    }
    // Update quit overlay id
    func setQuitOverlayId(_ id: UUID?) {
        quitOverlayId = id
    }
    // Update stats overlay id
    func setStatsOverlayId(_ id: UUID?) {
        statsOverlayId = id
    }
    // Update library overlay id
    func setLibraryOverlayId(_ id: UUID?) {
        libraryOverlayId = id
    }
    // Update active overlay enum
    func setActiveOverlay(_ overlay: ActiveOverlay) {
        activeOverlay = overlay
    }
}
