//
//  KeyCodes.swift
//  harryfan-reader
//
//  Created by @vt887 on 10/15/25.
//

import Foundation

/// Centralized key code constants — use `KeyCode.escape`, `KeyCode.f1`, etc.
/// Kept as an enum with static lets to mirror previous usage sites.
public enum KeyCode {
    public static let escape: UInt16 = 53
    public static let f1: UInt16 = 122
    public static let f2: UInt16 = 120
    public static let f3: UInt16 = 99
    public static let f4: UInt16 = 118
    public static let f5: UInt16 = 96
    public static let f6: UInt16 = 97
    public static let f7: UInt16 = 98
    public static let f8: UInt16 = 100
    public static let f9: UInt16 = 101
    public static let f10: UInt16 = 109
    public static let yKey: UInt16 = 16
    public static let nKey: UInt16 = 45
}
