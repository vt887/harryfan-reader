//
//  KeyHandler.swift
//  harryfan-reader
//
//  Created by @vt887 on 10/12/25.
//

import AppKit
import Foundation

// Class to handle key events for the main content screen
class KeyHandler {
    private weak var document: TextDocument?
    private var activeOverlay: ActiveOverlay = .none
    private var welcomeOverlayId: UUID?
    private var helpOverlayId: UUID?
    private var fileTextOverlayId: UUID?
    private var overlayLayers: [ScreenLayer]
    private var overlayOpacities: [UUID: Double]
    private var showingFilePicker: Bool
    private let addOverlay: (OverlayKind, Double) -> UUID
    private let removeOverlay: (UUID, Double) -> Void
    private let overlayManager: OverlayManager
    private let recentFilesManager: RecentFilesManager

    // Overlay state for key handling
    enum ActiveOverlay {
        case none
        case welcome
        case help
        case quit
        case custom
    }

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
        guard let document else { return }
        if AppSettings.shouldShowQuitMessage, !document.shouldShowQuitMessage {
            document.shouldShowQuitMessage = true
            return
        }
        NSApp.terminate(nil)
    }

    // Event handler separated for readability & testability
    func handleKeyEvent(_ event: NSEvent) -> NSEvent? {
        guard let document else { return event }
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
                    removeOverlay(quitId, 0.25)
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
                removeOverlay(wId, 0.25)
                welcomeOverlayId = nil
                activeOverlay = .none
                return nil
            }
        case .help:
            // Dismiss on Escape only
            if event.keyCode == KeyCode.escape {
                DebugLogger.log("Help overlay: ESC pressed, dismissing overlay.")
                if let hId = helpOverlayId {
                    removeOverlay(hId, 0.25)
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
            removeOverlay(wId, 0.25)
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
                helpOverlayId = addOverlay(.help, 0.25)
                DebugLogger.log("Help overlay shown (id=\(helpOverlayId!))")
            }
            return nil
        }
        switch event.keyCode {
        case KeyCode.f10:
            DebugLogger.log("F10 key pressed")
            document.shouldShowQuitMessage = true
            // Set the quit overlay and activeOverlay explicitly
            let quitId = addOverlay(.quit, 0.25)
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
                removeOverlay(hId, 0.25)
                helpOverlayId = nil
                DebugLogger.log("Help overlay hidden")
            } else {
                if let wId = welcomeOverlayId {
                    removeOverlay(wId, 0.25)
                    welcomeOverlayId = nil
                }
                helpOverlayId = addOverlay(.help, 0.25)
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

    // Update overlay IDs
    func setWelcomeOverlayId(_ id: UUID?) {
        welcomeOverlayId = id
    }

    func setHelpOverlayId(_ id: UUID?) {
        helpOverlayId = id
    }

    func setFileTextOverlayId(_ id: UUID?) {
        fileTextOverlayId = id
    }

    func setActiveOverlay(_ overlay: ActiveOverlay) {
        activeOverlay = overlay
    }
}
