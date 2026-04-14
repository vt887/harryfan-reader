# Contributing to HarryFan Reader

Thank you for your interest in contributing! This document provides guidelines and instructions for contributing to the HarryFan Reader project.

## Code of Conduct

We are committed to providing a welcoming and inspiring community for all. Please read and follow our Code of Conduct. If you witness or experience unacceptable behavior, please [report it](ISSUE_TEMPLATE/code_of_conduct_report.yml).

## Getting Started

### Prerequisites
- macOS 14.0 or later
- Swift 6.2
- Xcode 16+ (for SwiftUI development)

### Setting Up Development Environment

1. **Clone the repository:**
   ```bash
   git clone https://github.com/vt887/harryfan-reader.git
   cd harryfan-reader
   ```

2. **Install pre-commit hooks (optional but recommended):**
   ```bash
   make pre-commit
   ```
   This automatically formats code with swiftformat before each commit.

3. **Build the project:**
   ```bash
   make build
   ```

4. **Run tests:**
   ```bash
   make test
   ```

## Development Workflow

### Before Starting
1. Check [open issues](../../issues) and [pull requests](../../pulls) to avoid duplicate work
2. Create an issue to discuss significant changes before starting
3. Fork the repository and create a branch from `main`

### Code Style & Standards
- **Language:** Swift 6.2
- **Formatting:** Use `make lint` to auto-format code
- **Linting:** Use `make style` to check for linting issues
- **Testing:** All new features must include tests (Quick/Nimble framework)
- **Documentation:** Use triple-slash `///` comments for public APIs

### Making Changes
1. Create a descriptive branch name:
   ```bash
   git checkout -b feature/your-feature-name
   # or: git checkout -b fix/your-bug-name
   ```

2. Make your changes following [Code Conventions](../copilot-instructions.md#code-conventions)

3. Write or update tests:
   ```bash
   # Run specific test suite
   swift test --filter YourTestQuickSpec
   
   # Run all tests
   make test
   ```

4. Format and lint your code:
   ```bash
   make lint  # Auto-format with swiftformat
   make style # Check linting issues
   ```

5. Commit with a clear message:
   ```bash
   git commit -m "Fix navigation bug in large files

   - Fixed off-by-one error in line calculation
   - Added regression test for edge case
   - Performance impact: none"
   ```

### Submitting a Pull Request

1. **Push your branch:**
   ```bash
   git push origin feature/your-feature-name
   ```

2. **Open a Pull Request** on GitHub with:
   - Clear title and description
   - Reference to related issues (if any)
   - Type of change (bug fix, feature, etc.)
   - Confirmation that tests pass and code is formatted
   - Any breaking changes or performance considerations

3. **Address review feedback** promptly

4. **Wait for approval** from maintainers before merging

## Project Structure

```
harryfan-reader/
├── Sources/
│   └── HarryFanReader/
│       ├── App/              # Main application files
│       ├── Views/            # SwiftUI views (ContentView, SettingsView, etc.)
│       ├── Models/           # Data models (TextDocument, managers)
│       ├── Utilities/        # Helper functions and utilities
│       └── Fonts/            # PSF font resources
├── Tests/
│   └── HarryFanReaderTests/
│       └── *QuickSpec.swift  # Quick/Nimble test suites
├── .github/
│   ├── workflows/            # CI/CD workflows
│   └── ISSUE_TEMPLATE/       # Issue and PR templates
└── Makefile                  # Build and test commands
```

## Key Concepts

### Architecture Highlights
- **Reactive State Management:** @StateObject, @EnvironmentObject, @Published
- **Grid-Based Rendering:** 80x24 character cells with PSF fonts
- **CP866 Encoding:** Support for Cyrillic Fidonet-era text files
- **Persistent Storage:** UserDefaults for bookmarks, settings, recent files

See [Copilot Instructions](../copilot-instructions.md) for detailed architecture documentation.

### Testing Framework
- **Framework:** Quick/Nimble (BDD-style tests)
- **Naming:** `*QuickSpec.swift` files (e.g., `TextDocumentQuickSpec.swift`)
- **Pattern:** `describe`/`context`/`it` blocks
- **Matchers:** `.to(equal())`, `.to(beTrue())`, `.to(contain())`

Example test:
```swift
describe("TextDocument") {
  context("navigation") {
    it("should move to next line") {
      let doc = TextDocument(content: "line1\nline2\nline3")
      doc.nextLine()
      expect(doc.currentLine).to(equal(2))
    }
  }
}
```

## Common Tasks

### Adding a New Feature
1. Create an issue with the feature proposal
2. Add tests for the new functionality (TDD recommended)
3. Implement the feature in the appropriate module
4. Update documentation if needed
5. Submit a PR with clear description

### Fixing a Bug
1. Create a test that reproduces the bug
2. Fix the bug
3. Verify the test now passes
4. Check no other tests are broken
5. Submit a PR with bug details and reproduction steps

### Improving Performance
1. Identify the bottleneck (profiling recommended)
2. Implement optimization
3. Verify with benchmarks or timing tests
4. Document the improvement in the PR

## Useful Commands

```bash
# Build and test
make build
make test

# Code quality
make lint      # Format code (auto-fixes)
make style     # Check linting issues
make stat      # Line count statistics

# Run specific tests
swift test --filter TextDocumentQuickSpec/navigation

# Development mode (if available)
make run
```

## Getting Help

- **Questions about architecture?** See [Copilot Instructions](../copilot-instructions.md)
- **Issue with tests?** Check test suites in `Tests/HarryFanReaderTests/`
- **Need clarification?** Open a discussion or comment on related issues
- **Report a bug?** Use the [bug report template](ISSUE_TEMPLATE/bug_report.md)

## Recognition

Contributors will be recognized in:
- Pull request acknowledgments
- Project commit history
- Contributors section (if added in future)

## License

By contributing, you agree that your contributions will be licensed under the same license as the project (see LICENSE file).

---

**Thank you for contributing to HarryFan Reader! 🎉**
