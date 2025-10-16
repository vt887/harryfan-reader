//
//  Colors.swift
//  harryfan-reader
//
//  Created by @vt887 on 9/27/25.
//

import SwiftUI

// Enum for color constants used in the app
enum Colors {
    // Define colors based on AppTheme
    static var theme: AppTheme {
        AppTheme.theme(for: Settings.appearance)
    }
}

// Struct for app theme color definitions
struct AppTheme {
    let background: Color
    let foreground: Color
    let titleBarBackground: Color
    let titleBarForeground: Color
    let menuBarBackground: Color
    let menuBarForeground: Color
    let menuBarNumbers: Color
    let menuBarText: Color
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
                menuBarNumbers: Color(red: 0.8, green: 0.8, blue: 0.8), // Light gray
                menuBarText: .black,
                bottomMenuForeground: Color(red: 0.2, green: 0.2, blue: 0.2), // Dark gray
                helpMenuBackground: Color(red: 0.8, green: 0.8, blue: 0.8), // Light gray
                helpMenuForeground: Color(red: 0.2, green: 0.2, blue: 0.2), // Dark gray
            )
        case .dark:
            AppTheme(
                background: .black,
                foreground: .white,
                titleBarBackground: Color(red: 0.2, green: 0.2, blue: 0.2),
                titleBarForeground: .white,
                menuBarBackground: Color(red: 0.1, green: 0.1, blue: 0.1),
                menuBarForeground: .white,
                menuBarNumbers: Color(red: 0.8, green: 0.8, blue: 0.8), // Light gray
                menuBarText: .black,
                bottomMenuForeground: Color(red: 0.8, green: 0.8, blue: 0.8),
                helpMenuBackground: Color(red: 0.8, green: 0.8, blue: 0.8), // Light gray
                helpMenuForeground: Color(red: 0.2, green: 0.2, blue: 0.2), // Dark gray
            )
        case .blue:
            AppTheme(
                background: Color(red: 0.0, green: 0.0, blue: 0.66), // #0000AA
                foreground: Color(red: 0.33, green: 1.0, blue: 1.0), // #55FFFF
                titleBarBackground: Color(red: 0.667, green: 0.667, blue: 0.667), // Light gray
                titleBarForeground: .black,
                menuBarBackground: Color(red: 0.29, green: 0.65, blue: 0.65), // Teal (#4BA5A7)
                menuBarForeground: .black,
                menuBarNumbers: Color(red: 0.8, green: 0.8, blue: 0.8), // Light gray
                menuBarText: .black,
                bottomMenuForeground: Color(red: 0.9, green: 0.9, blue: 0.9),
                helpMenuBackground: Color(red: 0.8, green: 0.8, blue: 0.8), // Light gray
                helpMenuForeground: Color(red: 0.2, green: 0.2, blue: 0.2), // Dark gray
            )
        }
    }
}
