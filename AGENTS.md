# AGENTS.md — For AI coding agents (Swift project)

This file is a compact, actionable guide to help automated agents become
productive in this repository. It focuses on the concrete patterns, files,
and commands you will need to understand and change the code safely.

## Quick snapshot
- macOS-only SwiftUI app (Package.swift, platform `.macOS(.v14)`).
- Purpose: render CP866/Fidonet-era text in an MS-DOS 80x24 grid using a
  bitmap PSF-style font (`Sources/HarryFanReader/Fonts/vdu.8x16.raw`).

## Key entry points & architecture
- App root: `Sources/HarryFanReader/HarryFanReaderApp.swift` — creates
  `@StateObject` singletons and injects them via `.environmentObject(...)`.
- View orchestration: `ContentView.swift` (UI shell). Primary state lives in
  `TextDocument.swift` (file content, navigation, topLine/currentLine).
- Rendering: `ScreenView.swift` draws a character-cell grid (not Text);
  glyphs come from `FontManager.swift` via `getCharacterBitmap`.
- Overlays & input: `Overlays.swift` + `MainContentScreenView` inside
  `ContentView.swift` (keyboard handling and overlay composition).

## Communication & command patterns
- Commands are delivered via NotificationCenter: see `AppCommands.swift`.
- `NotificationsHandlers.applyNotifications(...)` maps notifications to
  `TextDocument` and manager operations — treat it as the command bus.
- Status bar and menu items also post the same notifications
  (`StatusBarManager.swift`). When adding a command, wire it via
  `AppCommands` and `NotificationsHandlers`.

## Data, fonts, and persistence
- Text decoding: `TextDocument.openFile` -> `decodeCP866` uses
  `UnicodePoints.swift` mapping for CP866 → Unicode.
- Font lookup: `FontManager.findFontURL` checks `~/.harryfan/fonts/*.raw`
  then bundled `vdu.8x16.raw`.
- Persistence: managers use `UserDefaults` keys (see
  `BookmarkManager.swift`, `RecentFilesManager.swift`, `AppSettings.swift`).

## Tests & developer workflow
- Build: `make build` (Makefile sets SWIFT_FLAGS for macOS SDK).
- Run: `make run`.
- Tests: `make test` or `swift test --filter <QuickSpecName>` (Quick/Nimble
  suites live in `Tests/HarryFanReaderTests/*QuickSpec.swift`).

## Beads + GitHub Workflow
- GitHub Projects is the working planner and status tracker for humans.
- Beads is the execution graph and source of truth for dependency order.
- Use GitHub Projects to show lifecycle state, assignee, milestone, PR, and review.
- Use Beads to decide what is actually ready to work on next and to enforce `blocks`/`blocked-by` flow.
- Treat Beads as the source of truth for execution order. Always work the next `bd ready` issue that is unblocked by dependencies.
- Release work is sequential. Keep the release chain linked with `blocks` so each release blocks the next release.
- For each release issue, add `blocks` dependencies from all required sub-issues to that release issue.
- GitHub Projects v2 is the status tracker for release execution.
- Project status flow:
  - `Open` or `To Do` -> issue exists but not started
  - `In Progress` -> active implementation is underway
  - `Testing` -> PR exists and CI is green
  - `Done` -> PR merged and Beads issue closed
- Create the PR only after the last sub-issue for that release is closed.
- Use the release branch that already matches the release name.
- Every meaningful commit on a feature/release branch must compile successfully.
- After every successful commit, add a short GitHub comment to the corresponding sub-issue. Keep it to 1-3 sentences, explain what changed and why, and mention that the build/compile succeeded.
- Each sub-issue should have at least one commit and at least one comment. More comments are encouraged when they clarify incremental progress.
- PR metadata:
  - assignee: `vt887`
  - reviewer: GitHub Copilot code review
  - milestone: derived from the issue name suffix
    - `-alpha` -> alpha milestone
    - `-beta` -> beta milestone
    - `-gamma` -> gamma milestone
    - `1.0` -> release milestone
- Move the GitHub Project item to `Testing` only after both conditions are true:
  - the PR exists
  - CI is green
- Merge the PR only after testing passes.
- Close the Beads issue only after the PR is merged.
- After merge, move the GitHub Project item to `Done`.
- Keep release and dependency links accurate in both Beads and GitHub Projects.

## macOS UI Testing Strategy
- This app is a native macOS user-facing application, so functional testing should prioritize human-like interaction over pure unit coverage for UI workflows.
- Preferred testing layers:
  - Manual smoke testing for real user flows such as opening files, keyboard navigation, Help overlay, search, bookmarks, recent files, settings, and quitting.
  - XCTest UI tests for repeatable macOS UI automation using the accessibility tree.
  - Accessibility-driven automation for menu commands, keyboard shortcuts, window focus, and overlay dismissal.
  - Targeted unit tests for pure logic such as search, encoding, bookmarks, and persistence.
- For user-like behavior, test these flows explicitly:
  - open a text file
  - navigate through content with keyboard
  - open and close Help
  - search text and move between matches
  - add/remove bookmarks
  - open recent files
  - change settings
  - verify quitting and window lifecycle
- When a feature changes UI behavior, add at least one automated smoke test if the flow is accessible through XCTest.
- If a flow is difficult to automate reliably, keep a short manual test checklist in the PR description and validate it before merge.

## Pre-commit (use https://github.com/pre-commit)
- This repo includes `scripts/pre-commit.sh` used by legacy `make pre-commit`.
  Prefer the pre-commit framework for reproducible hooks. Example config is
  provided in `.pre-commit-config.yaml` (runs `swiftformat` and `swiftlint`
  when available). Install with:

```bash
python3 -m pip install --user pre-commit
pre-commit install
pre-commit run --all-files
```

## Files to inspect for common edits
- Navigation/search bugs: `Sources/HarryFanReader/TextDocument.swift`
  + tests: `Tests/HarryFanReaderTests/TextDocumentQuickSpec.swift`.
- Keyboard/overlay: `Sources/HarryFanReader/ContentView.swift` and
  `Sources/HarryFanReader/Overlays.swift`.
- Rendering problems: `Sources/HarryFanReader/ScreenView.swift`,
  `Sources/HarryFanReader/FontManager.swift`, `Sources/HarryFanReader/Colors.swift`.

## Conventions agents should follow
- Use the existing Makefile targets for build/run/test to match CI.
- Formatting/linting: `swiftformat` & `swiftlint` are the canonical tools;
  the repo's `scripts/pre-commit.sh` documents how they are used.
- Use `DebugLogger` (not print) and `AppSettings.debug` guards for logs.

If you need more detail on any area (hook config, example change flow,
or tests to run for a specific module), ask and I will expand the section
or create small helper scripts/configs.

<!-- BEGIN BEADS INTEGRATION v:1 profile:minimal hash:ca08a54f -->
## Beads Issue Tracker

This project uses **bd (beads)** for issue tracking. Run `bd prime` to see full workflow context and commands.

### Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --claim  # Claim work
bd close <id>         # Complete work
```

### Rules

- Use `bd` for ALL task tracking — do NOT use TodoWrite, TaskCreate, or markdown TODO lists
- Run `bd prime` for detailed command reference and session close protocol
- Use `bd remember` for persistent knowledge — do NOT use MEMORY.md files
- Session completion and GitHub/Beads workflow are defined in the earlier "Beads + GitHub Workflow" section
<!-- END BEADS INTEGRATION -->
