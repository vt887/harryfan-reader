//
//  DebugLogger.swift
//  harryfan-reader
//
//  Created by @vt887 on 10/4/25.
//

import Foundation

// Debug logging utility
enum DebugLogger {
    static func log(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        guard AppSettings.debug else { return }
        let fileName = (file as NSString).lastPathComponent
        print("[\(fileName):\(line)] \(function): \(message)")
    }

    static func logError(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        guard AppSettings.debug else { return }
        let fileName = (file as NSString).lastPathComponent
        print("ERROR [\(fileName):\(line)] \(function): \(message)")
    }

    static func logWarning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        guard AppSettings.debug else { return }
        let fileName = (file as NSString).lastPathComponent
        print("WARNING [\(fileName):\(line)] \(function): \(message)")
    }
}
