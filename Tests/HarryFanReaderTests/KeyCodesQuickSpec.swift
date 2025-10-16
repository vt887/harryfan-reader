//
//  KeyCodesQuickSpec.swift
//  HarryFanReaderTests
//
//  Created by @vt887 on 10/15/25.
//

import AppKit
@testable import HarryFanReader
import Nimble
import Quick

final class KeyCodesQuickSpec: QuickSpec {
    override class func spec() {
        describe("KeyCode constants") {
            it("has expected numeric values for control keys") {
                expect(KeyCode.escape).to(equal(UInt16(53)))
                expect(KeyCode.f1).to(equal(UInt16(122)))
                expect(KeyCode.f2).to(equal(UInt16(120)))
                expect(KeyCode.f3).to(equal(UInt16(99)))
                expect(KeyCode.f10).to(equal(UInt16(109)))
            }

            it("has expected values for letter keys used in dialogs") {
                expect(KeyCode.yKey).to(equal(UInt16(16)))
                expect(KeyCode.nKey).to(equal(UInt16(45)))
            }

            it("has unique numeric values for all defined keys") {
                let values: [UInt16] = [
                    KeyCode.escape, KeyCode.f1, KeyCode.f2, KeyCode.f3, KeyCode.f4,
                    KeyCode.f5, KeyCode.f6, KeyCode.f7, KeyCode.f8, KeyCode.f9, KeyCode.f10,
                    KeyCode.yKey, KeyCode.nKey
                ]
                let unique = Set(values)
                expect(unique.count).to(equal(values.count))
            }
        }
    }
}
