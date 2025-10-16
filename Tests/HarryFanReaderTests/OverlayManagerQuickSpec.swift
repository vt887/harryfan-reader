//
//  OverlayManagerQuickSpec.swift
//  HarryFanReaderTests
//
//  Created by @vt887 on 10/15/25.
//

@testable import HarryFanReader
import Nimble
import Quick

final class OverlayManagerQuickSpec: QuickSpec {
    override class func spec() {
        describe("OverlayManager stack behavior") {
            it("adds overlays and prevents duplicates") {
                let manager = OverlayManager()
                manager.addOverlay(.help)
                expect(manager.overlays).to(contain(.help))
                // adding again should not duplicate
                manager.addOverlay(.help)
                expect(manager.overlays.count(where: { $0 == .help })).to(equal(1))
            }

            it("removes overlays correctly") {
                let manager = OverlayManager()
                manager.addOverlay(.help)
                manager.addOverlay(.about)
                manager.removeOverlay(.help)
                expect(manager.overlays).toNot(contain(.help))
                expect(manager.overlays).to(contain(.about))
            }

            it("removeAll clears overlays") {
                let manager = OverlayManager()
                manager.addOverlay(.help)
                manager.addOverlay(.about)
                manager.removeAll()
                expect(manager.overlays.isEmpty).to(beTrue())
            }

            it("setOpacity clamps values between 0 and 1") {
                let manager = OverlayManager()
                manager.setOpacity(-1.0)
                expect(manager.getOpacity()).to(equal(0.0))
                manager.setOpacity(2.0)
                expect(manager.getOpacity()).to(equal(1.0))
                manager.setOpacity(0.5)
                expect(manager.getOpacity()).to(equal(0.5))
            }

            it("removeHelpOverlay removes only help overlays") {
                let manager = OverlayManager()
                manager.addOverlay(.help)
                manager.addOverlay(.about)
                manager.removeHelpOverlay()
                expect(manager.overlays).toNot(contain(.help))
                expect(manager.overlays).to(contain(.about))
            }
        }
    }
}
