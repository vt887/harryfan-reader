//
//  OverlayPoliciesQuickSpec.swift
//  HarryFanReaderTests
//
//  Created by @vt887 on 10/15/25.
//

@testable import HarryFanReader
import Nimble
import Quick

final class OverlayPoliciesQuickSpec: QuickSpec {
    override class func spec() {
        describe("OverlayPolicies") {
            it("returns expected activities for welcome") {
                let activities = OverlayPolicies.allowedActivities(for: .welcome)
                expect(activities.allowAnyKeyToDismiss).to(beFalse())
                expect(activities.dismissKeyCodes.isEmpty).to(beTrue())
                expect(activities.allowActionBarSecondaryClick).to(beFalse())
            }

            it("returns expected activities for help") {
                let activities = OverlayPolicies.allowedActivities(for: .help)
                expect(activities.allowAnyKeyToDismiss).to(beFalse())
                expect(activities.dismissKeyCodes.contains(KeyCode.f1)).to(beTrue())
                expect(activities.dismissKeyCodes.contains(KeyCode.escape)).to(beTrue())
                expect(activities.allowActionBarSecondaryClick).to(beTrue())
            }

            it("returns expected activities for quit") {
                let activities = OverlayPolicies.allowedActivities(for: .quit)
                expect(activities.allowAnyKeyToDismiss).to(beFalse())
                expect(activities.dismissKeyCodes.contains(KeyCode.escape)).to(beTrue())
                expect(activities.dismissKeyCodes.contains(KeyCode.yKey)).to(beTrue())
                expect(activities.dismissKeyCodes.contains(KeyCode.nKey)).to(beTrue())
                expect(activities.allowActionBarSecondaryClick).to(beTrue())
            }

            it("returns expected activities for about") {
                let activities = OverlayPolicies.allowedActivities(for: .about)
                expect(activities.allowAnyKeyToDismiss).to(beFalse())
                expect(activities.dismissKeyCodes).to(contain(KeyCode.escape))
                expect(activities.allowActionBarSecondaryClick).to(beFalse())
            }
        }
    }
}
