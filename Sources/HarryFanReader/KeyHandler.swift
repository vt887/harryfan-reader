//
//  KeyHandler.swift
//  harryfan-reader
//
//  Created by @vt887 on 10/12/25.
//

import AppKit
import Foundation

// Overlay state for key handling (moved to top-level so multiple components can use it)
enum ActiveOverlay {
    case none
    case welcome
    case help
    case quit
    case about
}

// Class to handle key events for the main content screen
class KeyHandler {
    private weak var document: TextDocument?
    private var activeOverlay: ActiveOverlay = .none
    private var welcomeOverlayId: UUID?
    private var helpOverlayId: UUID?
    private var quitOverlayId: UUID?
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
        if AppSettings.shouldShowQuitMessage, !document.shouldShowQuitMessage {
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
        // Remove quit overlay layer (if any)
        if let qId = quitOverlayId {
            removeOverlay(qId, 0.25)
            quitOverlayId = nil
        }
        // Also remove welcome/help overlays so we restore the previous content screen
        if let wId = welcomeOverlayId {
            removeOverlay(wId, 0.25)
            welcomeOverlayId = nil
        }
        if let hId = helpOverlayId {
            removeOverlay(hId, 0.25)
            helpOverlayId = nil
        }
    }

    // Helper to map ActiveOverlay to OverlayKind
    private func overlayKind(from active: ActiveOverlay) -> OverlayKind? {
        switch active {
        case .welcome: return .welcome
        case .help: return .help
        case .quit: return .quit
        case .about: return .about
        case .none: return nil
        }
    }

    // Event handler separated for readability & testability
    func handleKeyEvent(_ event: NSEvent) -> NSEvent? {
        guard let document else { return event }
        DebugLogger.log("Key pressed: keyCode=\(event.keyCode), characters='\(event.charactersIgnoringModifiers ?? "")', activeOverlay=\(activeOverlay)")

        // If there's an active overlay, consult OverlayPolicies for dismissal behavior
        if activeOverlay != .none, let kind = overlayKind(from: activeOverlay) {
            let policy = OverlayPolicies.allowedActivities(for: kind)

            // Special handling for quit overlay: 'y' confirms quit, 'n' or dismiss keys cancel
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

            // Welcome overlay: dismiss on any key if allowed, otherwise only on configured keys
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

            // Help overlay: dismiss only on configured keys (e.g., F1)
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
                } else {
                    DebugLogger.log("Help overlay: ignored key.")
                    return nil
                }
            }

            // About overlay: dismiss on configured keys; when dismissed, clear tracked overlays
            if kind == .about {
                let isDismissKey = policy.dismissKeyCodes.contains(event.keyCode)
                if policy.allowAnyKeyToDismiss || isDismissKey {
                    DebugLogger.log("About overlay: dismissing per policy.")
                    if let hId = helpOverlayId {
                        removeOverlay(hId, 0.25)
                        helpOverlayId = nil
                    }
                    if let wId = welcomeOverlayId {
                        removeOverlay(wId, 0.25)
                        welcomeOverlayId = nil
                    }
                    if let qId = quitOverlayId {
                        removeOverlay(qId, 0.25)
                        quitOverlayId = nil
                    }
                    overlayManager.removeAll()
                    activeOverlay = .none
                    return nil
                } else {
                    DebugLogger.log("About overlay: ignored key.")
                    return nil
                }
            }
        }

        // Remove welcome overlay on first key if present (fallback for when activeOverlay is .none)
        if let wId = welcomeOverlayId {
            removeOverlay(wId, 0.25)
            welcomeOverlayId = nil
            DebugLogger.log("Welcome overlay removed (keyCode=\(event.keyCode))")
        }

        // NOTE: Do NOT remove the help overlay here; help overlay dismissal is controlled
        // by the active overlay logic (help case) and by F1 only. This prevents other keys
        // from unexpectedly hiding the help overlay.

        // F2 toggles word wrap
        if event.keyCode == KeyCode.f2 {
            document.toggleWordWrap()
            DebugLogger.log("Word wrap toggled (keyCode=\(event.keyCode))")
            return nil
        }
        // F1 toggle help
        if event.keyCode == KeyCode.f1 {
            if let hId = helpOverlayId {
                removeOverlay(hId, 0.25)
                helpOverlayId = nil
                DebugLogger.log("Help overlay hidden (keyCode=\(event.keyCode))")
            } else {
                // Ensure welcome removed before showing help
                if let wId = welcomeOverlayId {
                    removeOverlay(wId, 0.25)
                    welcomeOverlayId = nil
                    DebugLogger.log("Welcome overlay removed before showing help")
                }
                let newId = addOverlay(.help, 0.25)
                helpOverlayId = newId
                DebugLogger.log("Help overlay shown (id=\(newId))")
            }
            return nil
        }
        switch event.keyCode {
        case KeyCode.f10:
            DebugLogger.log("F10 key pressed")
            document.shouldShowQuitMessage = true
            // Set the quit overlay and activeOverlay explicitly
            let quitId = addOverlay(.quit, 0.25)
            quitOverlayId = quitId
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
                 removeOverlay(hId, 0.25)
                 helpOverlayId = nil
                 DebugLogger.log("Help overlay hidden")
             } else {
                 if let wId = welcomeOverlayId {
                     removeOverlay(wId, 0.25)
                     welcomeOverlayId = nil
                 }
                 if let qId = quitOverlayId {
                     removeOverlay(qId, 0.25)
                     quitOverlayId = nil
                 }
                 let newId = addOverlay(.help, 0.25)
                 helpOverlayId = newId
                 DebugLogger.log("Help overlay shown")
             }
             return nil
         default:
             return event
         }
     }

    // Update overlay IDs (used by the view to inform handler of tracked ids)
    func setWelcomeOverlayId(_ id: UUID?) {
        welcomeOverlayId = id
    }

    func setHelpOverlayId(_ id: UUID?) {
        helpOverlayId = id
    }

    func setQuitOverlayId(_ id: UUID?) {
        quitOverlayId = id
    }

    func setActiveOverlay(_ overlay: ActiveOverlay) {
        activeOverlay = overlay
    }
}
