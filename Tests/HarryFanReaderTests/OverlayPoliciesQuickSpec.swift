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
    // Main test entry point for OverlayPolicies
    override class func spec() {
        describe("OverlayPolicies") {
            it("returns expected activities for welcome") {
                Self.testWelcomeActivities()
            }
            it("returns expected activities for help") {
                Self.testHelpActivities()
            }
            it("returns expected activities for quit") {
                Self.testQuitActivities()
            }
            it("returns expected activities for about") {
                Self.testAboutActivities()
            }
            it("returns expected activities for statistics") {
                Self.testStatisticsActivities()
            }
        }
    }

    // Tests allowed activities for the welcome overlay
    private static func testWelcomeActivities() {
        let activities = OverlayPolicies.allowedActivities(for: .welcome)
        expect(activities.allowAnyKeyToDismiss).to(beTrue())
        expect(activities.dismissKeyCodes.isEmpty).to(beTrue())
        expect(activities.allowActionBarSecondaryClick).to(beFalse())
    }

    // Tests allowed activities for the help overlay
    private static func testHelpActivities() {
        let activities = OverlayPolicies.allowedActivities(for: .help)
        expect(activities.allowAnyKeyToDismiss).to(beFalse())
        expect(activities.dismissKeyCodes.contains(KeyCode.f1)).to(beTrue())
        expect(activities.dismissKeyCodes.contains(KeyCode.escape)).to(beTrue())
        expect(activities.allowActionBarSecondaryClick).to(beTrue())
    }

    // Tests allowed activities for the quit overlay
    private static func testQuitActivities() {
        let activities = OverlayPolicies.allowedActivities(for: .quit)
        expect(activities.allowAnyKeyToDismiss).to(beFalse())
        expect(activities.dismissKeyCodes.contains(KeyCode.escape)).to(beTrue())
        expect(activities.dismissKeyCodes.contains(KeyCode.yKey)).to(beTrue())
        expect(activities.dismissKeyCodes.contains(KeyCode.nKey)).to(beTrue())
        expect(activities.allowActionBarSecondaryClick).to(beTrue())
    }

    // Tests allowed activities for the about overlay
    private static func testAboutActivities() {
        let activities = OverlayPolicies.allowedActivities(for: .about)
        expect(activities.allowAnyKeyToDismiss).to(beFalse())
        expect(activities.dismissKeyCodes).to(contain(KeyCode.escape))
        expect(activities.allowActionBarSecondaryClick).to(beFalse())
    }

    // Tests allowed activities for the statistics overlay
    private static func testStatisticsActivities() {
        let activities = OverlayPolicies.allowedActivities(for: .statistics)
        expect(activities.allowAnyKeyToDismiss).to(beTrue())
        expect(activities.allowActionBarSecondaryClick).to(beFalse())
    }
}
