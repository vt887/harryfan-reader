# Copilot Instructions for HarryFan Reader

## Project Overview

HarryFan Reader is a macOS-exclusive text viewer application written in Swift with SwiftUI. It emulates classic MS-DOS aesthetics with CP866 encoding support (particularly for Cyrillic text from the Fidonet era). The application is a full executable built with Swift Package Manager targeting macOS 14.0+.

## Build, Test, and Lint Commands

### Building
```bash
# Using Make (recommended)
make build

# Using Swift Package Manager directly
swift build --build-tests -Xswiftc -sdk -Xswiftc $(xcrun --sdk macosx --show-sdk-path) -Xswiftc -no-verify-emitted-module-interface
```

### Running
```bash
# Using Make
make run

# Using Swift directly
swift run
```

### Testing
```bash
# Run all tests
make test
# or: swift test -Xswiftc -sdk -Xswiftc $(xcrun --sdk macosx --show-sdk-path) -Xswiftc -no-verify-emitted-module-interface

# Run a specific test suite (uses Quick/Nimble test names)
swift test --filter TextDocumentQuickSpec

# Run an individual test
swift test --filter TextDocumentQuickSpec/TextDocument/navigation/goto_line
```

Test suites use the Quick/Nimble framework and follow the naming pattern `*QuickSpec.swift`. Key test suites:
- `TextDocumentQuickSpec` - Core document navigation and search
- `BookmarkManagerQuickSpec` - Bookmark persistence and navigation
- `FontManagerQuickSpec` - Font loading and CP866 character conversion
- `UtilityQuickSpec` - Configuration and utility functions

### Linting and Formatting
```bash
# Format code with swiftformat
make lint

# Format and fix linting issues with swiftlint
make style
```

### Other Commands
```bash
# Line count of source files
make stat

# Install pre-commit hook
make pre-commit
```

## Architecture

### Core Application Structure

#### Singletons (created as @StateObject at HarryFanReaderApp root)
- **FontManager** - PSF font loading, glyph bitmap generation, CP866 conversion; passed via @EnvironmentObject
- **BookmarkManager** - Bookmark persistence (UserDefaults) and navigation; passed via @EnvironmentObject
- **RecentFilesManager** - Recent files list persistence; passed via @EnvironmentObject
- **StatusBarManager** - Menu bar status display updates; passed via @EnvironmentObject
- **OverlayManager** - Overlay/modal state coordination; passed via @EnvironmentObject

#### View Hierarchy
- **HarryFanReaderApp** - @main entry point; creates all manager singletons as @StateObject, injects as @EnvironmentObject to children
- **ContentView** - Main container view; receives @EnvironmentObject TextDocument and managers from HarryFanReaderApp
  - **MainContentScreenView** - Text rendering viewport (grid-based character cell display)
  - **TitleBar** - Displays current file name and status
  - **BottomBar** - Shows current line, search results, help text
  - **MenuBar** - Command menu (keyboard shortcuts)
- **SettingsView** - Preferences UI; receives same TextDocument instance via @EnvironmentObject from HarryFanReaderApp Settings scene
- **SearchView** - Text search modal
- **Overlays** - Dialog boxes and modals

#### Models & State
- **TextDocument** - Observable object (@Published properties) managing document content, navigation state (currentLine, topLine), and encoding metadata; created as @StateObject at HarryFanReaderApp root and passed to both ContentView and SettingsView
- **AppSettings** - Global configuration constants (screen dimensions, default fonts, appearance, etc.); use AppSettings.propertyName everywhere

#### Utilities
- **UnicodePoints** - CP866 to Unicode mapping tables
- **DebugLogger** - Diagnostic logging (use instead of print)
- **NotificationsHandlers** - File event handlers
- **Messages** - UI strings and welcome text
- **Colors** - DOS-style color definitions (background, foreground, theme)

### Key Design Patterns

#### State Management
- **@StateObject**: Used only at HarryFanReaderApp root for all singletons (FontManager, BookmarkManager, RecentFilesManager, StatusBarManager, OverlayManager, TextDocument)
- **@EnvironmentObject**: All singletons injected into entire subtree via `.environmentObject()` on WindowGroup and Settings scenes
- **@ObservedObject**: Sub-views receive manager or TextDocument reference to react to state changes
- **Single source of truth**: TextDocument is created once in HarryFanReaderApp and passed to both ContentView and SettingsView, ensuring they share the same document state

#### Reactive Rendering
- SwiftUI @Published properties in managers and TextDocument trigger view updates
- ScreenView is grid-based character rendering (not line-by-line)—each cell (ScreenCell) holds character, foreground color, background color
- Views marked with @ObservedObject on managers ensure they redraw when manager state changes

#### Font Loading
- PSF (PC Screen Font) format for authentic MS-DOS appearance
- FontManager loads `vdu.8x16.raw` from bundle at startup
- Character glyphs are 8x16 pixels; entire screen is 80x24 characters

### CP866 Encoding Pipeline
1. Raw file data is detected for encoding (with CP866 fallback for Cyrillic)
2. `FontManager.convertCharacter()` maps CP866 byte values to Unicode equivalents
3. Special handling for:
   - Box drawing characters (─, │, ┌, ┐, ═, ║, ╔, ╗, etc.)
   - Block characters (█, ▄, ▌, ▐, ░, ▒, ▓)
   - Cyrillic letters with diacritics (Ё, є, ї, Ў, etc.)
   - Mathematical symbols (√, ≤, ≥, ≈)

## Code Conventions

### Swift Style
- Swift version: 6.2 (enforce with swiftformat)
- File header format:
  ```swift
  //
  //  FileName.swift
  //  harryfan-reader
  //
  //  Created by @vt887 on date.
  //
  ```
- Triple-slash `///` comments for public declarations (generates documentation)
- Concise inline comments only where logic isn't obvious

### View and Component Naming
- SwiftUI views use `*View.swift` naming (e.g., `SettingsView.swift`)
- Overlay/modal components in `Overlays.swift`
- UI chrome (bars, menus) in `*Bar.swift` files
- Keep components focused—decompose large views into smaller subviews

### Observable Objects & State
- All managers and TextDocument conform to `ObservableObject` with `@Published` properties
- TextDocument handles all document operations (navigation, search, encoding); sub-views should never manipulate content directly
- Manager updates (e.g., bookmark changes, font changes) automatically propagate to all observing views
- **State synchronization**: Keep managers and TextDocument in sync via their update methods; avoid direct property mutation from views

### Configuration
- All hardcoded constants belong in `AppSettings`
- Use `AppSettings.propertyName` throughout the app (single source of truth)
- This includes screen dimensions, default fonts, colors, wrap width, etc.

### Testing
- Use Quick/Nimble framework for all tests (not XCTest directly)
- Follow BDD style: `describe`, `context`, `it` blocks
- Test names describe behavior, not implementation
- Use `beforeEach`/`afterEach` for setup/teardown
- Prefer `.to(equal())`, `.to(beTrue())`, `.to(contain())` matchers over XCTest assertions

### Error Handling
- Use `DebugLogger.log()` for diagnostic output (not `print`)
- File operations should gracefully handle missing/unreadable files
- Encoding detection should fall back to CP866 when uncertain

## Important Notes

- **macOS only**: Uses AppKit (NSWindow, NSApp, NSApplicationDelegate) and UniformTypeIdentifiers—will not build for iOS
- **Font resources**: PSF font file (`vdu.8x16.raw`) bundled in `Sources/HarryFanReader/Fonts/` must be included in build
- **Grid-based rendering**: ScreenView renders via 2D character grid (80x24) with ScreenCell (character + colors), not line-by-line text
- **Multiple TextDocument instances**: ~~HarryFanReaderApp holds a @StateObject TextDocument (unused), ContentView creates its own (the actual editor). This is intentional to isolate editor state from app state.~~ **FIXED**: TextDocument is now created once in HarryFanReaderApp and shared as @EnvironmentObject with both ContentView and SettingsView.
- **UserDefaults persistence**: Bookmarks, recent files, font selection, and settings stored in UserDefaults—ensure test teardown clears these
- **Pre-commit hook**: Run `make pre-commit` to install swiftformat auto-formatting on commit
- **Large file handling**: TextDocument uses memory-efficient line-based storage for performance; splits content by newlines
- **AppDelegate role**: Initializes app appearance policy, sets anti-aliasing defaults, activates app on launch
