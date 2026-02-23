# HarryFan Reader Tests

This directory contains comprehensive tests for the HarryFan Reader application.

## Test Structure

The tests are organized into several test files:

- **TextDocumentTests.swift** - Tests for the main TextDocument class including:
  - Document navigation (goto line, page up/down, start/end)
  - Search functionality (forward/backward, case sensitive/insensitive)
  - Content access and manipulation
  - Title bar and menu bar formatting
  - File operations

- **BookmarkManagerTests.swift** - Tests for the BookmarkManager class including:
  - Bookmark creation and removal
  - Bookmark persistence (UserDefaults storage)
  - Bookmark navigation (next/previous)
  - File-specific bookmark filtering

- **FontManagerTests.swift** - Tests for the FontManager class including:
  - Font loading and initialization
  - Character bitmap generation
  - CP866 encoding conversion
  - Fallback glyph handling
  - System font creation

- **UtilityTests.swift** - Tests for utility functions and data structures including:
  - Settings constants and configuration
  - Messages and UI text
  - Unicode point mappings
  - Enums and data structures

## Running Tests

### Using Make
```bash
make test
```

### Using Swift Package Manager
```bash
swift test
```

### Running Specific Test Suites
```bash
# Run only TextDocument tests
swift test --filter TextDocumentTests

# Run only BookmarkManager tests  
swift test --filter BookmarkManagerTests

# Run only FontManager tests
swift test --filter FontManagerTests

# Run only Utility tests
swift test --filter UtilityTests
```

### Running Individual Tests
```bash
# Run a specific test method
swift test --filter TextDocumentTests.testSearchForward
```

## Test Coverage

The test suite covers:

- ✅ Core document functionality (navigation, search, content access)
- ✅ Bookmark management and persistence
- ✅ Font loading and character rendering
- ✅ Configuration and utility functions
- ✅ Edge cases and error conditions
- ✅ Performance testing for critical paths

## Notes

- Tests use XCTest framework
- Some tests may require macOS-specific functionality (AppKit)
- Performance tests are included but may vary based on system performance
- Tests clean up after themselves (e.g., clearing UserDefaults)
