//
//  Colors.swift
//  harryfan-reader
//
//  Created by @vt887 on 9/27/25.
//

import SwiftUI

enum Colors {
    static let scrollLaneColor = Color(red: 0.333, green: 1.0, blue: 0.333) // Bright green
    static let bookmarkColor = Color(red: 0.8, green: 0.2, blue: 0.2)

    // Define colors based on AppTheme
    static var theme: AppTheme {
        AppTheme.theme(for: AppSettings.appearance)
    }
}

struct AppTheme {
    let background: Color
    let foreground: Color
    let titleBarBackground: Color
    let titleBarForeground: Color
    let menuBarBackground: Color
    let menuBarForeground: Color
    let bottomMenuForeground: Color
    let helpMenuBackground: Color
    let helpMenuForeground: Color

    static func theme(for appearance: AppAppearance) -> AppTheme {
        switch appearance {
        case .light:
            AppTheme(
                background: .white,
                foreground: .black,
                titleBarBackground: Color(red: 0.8, green: 0.8, blue: 0.8), // Light gray
                titleBarForeground: .black,
                menuBarBackground: Color(red: 0.9, green: 0.9, blue: 0.9), // Very light gray
                menuBarForeground: .black,
                bottomMenuForeground: Color(red: 0.2, green: 0.2, blue: 0.2), // Dark gray
                helpMenuBackground: Color(red: 0.8, green: 0.8, blue: 0.8), // Light gray
                helpMenuForeground: Color(red: 0.2, green: 0.2, blue: 0.2) // Dark gray
            )
        case .dark:
            AppTheme(
                background: .black,
                foreground: .white,
                titleBarBackground: Color(red: 0.2, green: 0.2, blue: 0.2),
                titleBarForeground: .white,
                menuBarBackground: Color(red: 0.1, green: 0.1, blue: 0.1),
                menuBarForeground: .white,
                bottomMenuForeground: Color(red: 0.8, green: 0.8, blue: 0.8),
                helpMenuBackground: Color(red: 0.8, green: 0.8, blue: 0.8), // Light gray
                helpMenuForeground: Color(red: 0.2, green: 0.2, blue: 0.2) // Dark gray
            )
        case .blue:
            AppTheme(
                background: Color(red: 0.0, green: 0.0, blue: 0.667), // Sky blue
                foreground: Color(red: 0.333, green: 1.0, blue: 1.0), // Bright cyan
                titleBarBackground: Color(red: 0.667, green: 0.667, blue: 0.667), // Light gray
                titleBarForeground: .black,
                menuBarBackground: Color(red: 0.333, green: 1.0, blue: 1.0), // Bright cyan
                menuBarForeground: .black,
                bottomMenuForeground: Color(red: 0.9, green: 0.9, blue: 0.9),
                helpMenuBackground: Color(red: 0.8, green: 0.8, blue: 0.8), // Light gray
                helpMenuForeground: Color(red: 0.2, green: 0.2, blue: 0.2) // Dark gray
            )
        }
    }
}
