//
//  KeyHandlerQuickSpec.swift
//  HarryFanReaderTests
//
//  Created by @vt887 on 10/15/25.
//

import AppKit
@testable import HarryFanReader
import Nimble
import Quick

// Minimal fake document to observe side-effects
final class FakeTextDocument: TextDocument {
    var toggleCount = 0
    override func toggleWordWrap() {
        toggleCount += 1
        super.toggleWordWrap()
    }

    var gotoStartCalled = false
    override func gotoStart() {
        gotoStartCalled = true
        super.gotoStart()
    }

    var gotoEndCalled = false
    override func gotoEnd() {
        gotoEndCalled = true
        super.gotoEnd()
    }
}

final class KeyHandlerQuickSpec: QuickSpec {
    override class func spec() {
        describe("KeyHandler key handling") {
            var doc: FakeTextDocument!
            var overlayManager: OverlayManager!
            var recentFilesManager: RecentFilesManager!
            var added: [(OverlayKind, Double, UUID)]!
            var removed: [(UUID, Double)]!
            var handler: KeyHandler!

            beforeEach {
                doc = FakeTextDocument()
                overlayManager = OverlayManager()
                recentFilesManager = RecentFilesManager()
                added = []
                removed = []
            }

            func makeHandler() -> KeyHandler {
                let addClosure: (OverlayKind, Double) -> UUID = { kind, delay in
                    let id = UUID()
                    added.append((kind, delay, id))
                    return id
                }
                let removeClosure: (UUID, Double) -> Void = { id, delay in
                    removed.append((id, delay))
                }
                return KeyHandler(document: doc,
                                  overlayLayers: [],
                                  overlayOpacities: [:],
                                  showingFilePicker: false,
                                  addOverlay: addClosure,
                                  removeOverlay: removeClosure,
                                  overlayManager: overlayManager,
                                  recentFilesManager: recentFilesManager)
            }

            it("shows help on F1 when no overlay") {
                handler = makeHandler()
                let event = NSEvent.keyEvent(with: .keyDown,
                                             location: .zero,
                                             modifierFlags: [],
                                             timestamp: 0,
                                             windowNumber: 0,
                                             context: nil,
                                             characters: "",
                                             charactersIgnoringModifiers: "",
                                             isARepeat: false,
                                             keyCode: KeyCode.f1)!
                _ = handler.handleKeyEvent(event)
                expect(added).toNot(beEmpty())
                expect(added.first?.0).to(equal(.help))
            }

            it("toggles word wrap on F2") {
                handler = makeHandler()
                let event = NSEvent.keyEvent(with: .keyDown,
                                             location: .zero,
                                             modifierFlags: [],
                                             timestamp: 0,
                                             windowNumber: 0,
                                             context: nil,
                                             characters: "",
                                             charactersIgnoringModifiers: "",
                                             isARepeat: false,
                                             keyCode: KeyCode.f2)!
                _ = handler.handleKeyEvent(event)
                expect(doc.toggleCount).to(equal(1))
            }

            it("shows quit overlay on F10 and sets shouldShowQuitMessage") {
                handler = makeHandler()
                let event = NSEvent.keyEvent(with: .keyDown,
                                             location: .zero,
                                             modifierFlags: [],
                                             timestamp: 0,
                                             windowNumber: 0,
                                             context: nil,
                                             characters: "",
                                             charactersIgnoringModifiers: "",
                                             isARepeat: false,
                                             keyCode: KeyCode.f10)!
                _ = handler.handleKeyEvent(event)
                expect(doc.shouldShowQuitMessage).to(beTrue())
                expect(added.first?.0).to(equal(.quit))
            }

            it("cancels quit overlay on 'n' when quit active") {
                handler = makeHandler()
                // Set up a quit overlay id and active overlay state
                let quitId = UUID()
                handler.setQuitOverlayId(quitId)
                handler.setActiveOverlay(.quit)
                doc.shouldShowQuitMessage = true

                let event = NSEvent.keyEvent(with: .keyDown,
                                             location: .zero,
                                             modifierFlags: [],
                                             timestamp: 0,
                                             windowNumber: 0,
                                             context: nil,
                                             characters: "n",
                                             charactersIgnoringModifiers: "n",
                                             isARepeat: false,
                                             keyCode: 0)!
                _ = handler.handleKeyEvent(event)
                // cancelQuitOverlay should clear flag and call removeOverlay on quitId
                expect(doc.shouldShowQuitMessage).to(beFalse())
                expect(removed.contains { $0.0 == quitId }).to(beTrue())
            }

            it("dismisses help overlay on F1 when help active") {
                handler = makeHandler()
                let helpId = UUID()
                handler.setHelpOverlayId(helpId)
                handler.setActiveOverlay(.help)

                let event = NSEvent.keyEvent(with: .keyDown,
                                             location: .zero,
                                             modifierFlags: [],
                                             timestamp: 0,
                                             windowNumber: 0,
                                             context: nil,
                                             characters: "",
                                             charactersIgnoringModifiers: "",
                                             isARepeat: false,
                                             keyCode: KeyCode.f1)!
                _ = handler.handleKeyEvent(event)
                expect(removed.contains { $0.0 == helpId }).to(beTrue())
            }

            it("dismisses about overlay on ESC and clears manager overlays") {
                handler = makeHandler()
                // preload overlayManager with some overlays
                overlayManager.addOverlay(.help)
                overlayManager.addOverlay(.welcome)
                // set tracked ids
                let hId = UUID(); let wId = UUID(); let qId = UUID()
                handler.setHelpOverlayId(hId)
                handler.setWelcomeOverlayId(wId)
                handler.setQuitOverlayId(qId)
                handler.setActiveOverlay(.about)

                let event = NSEvent.keyEvent(with: .keyDown,
                                             location: .zero,
                                             modifierFlags: [],
                                             timestamp: 0,
                                             windowNumber: 0,
                                             context: nil,
                                             characters: "",
                                             charactersIgnoringModifiers: "",
                                             isARepeat: false,
                                             keyCode: KeyCode.escape)!
                _ = handler.handleKeyEvent(event)
                // overlayManager should be cleared
                expect(overlayManager.overlays.isEmpty).to(beTrue())
                // removeOverlay should have been called for each tracked id
                expect(removed.contains { $0.0 == hId }).to(beTrue())
                expect(removed.contains { $0.0 == wId }).to(beTrue())
                expect(removed.contains { $0.0 == qId }).to(beTrue())
            }
        }
    }
}

