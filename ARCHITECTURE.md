# Architecture

Ecran is a Swift Package split into four production targets:

- `Domain` owns settings, window actions, title extraction, snap models, and
  URL commands. It has no AppKit dependency.
- `WindowGeometry` calculates placement rects, gaps, grids, and snap hits.
- `Infrastructure` implements Accessibility, SkyLight fallbacks, hotkeys,
  persistence, and logging.
- `EcranCore` composes application state and SwiftUI. The small `Ecran`
  executable target starts the app.

`EcranRuntime` is the application composition root. `WindowMover` applies a
single action through Accessibility. `SwitcherController` owns the list
overlay. `SnapController` watches drags and shows a footprint. Settings persist
through the versioned, atomic `JSONSettingsStore`.

Placement shortcuts and drag-snap are isolated from the switcher: an ignored
app, or an open switcher, unbinds only window-action hotkeys. The switcher
stays available. Menu, URL, title-bar, and green-button actions still run.

## Reliability boundaries

- Persistence uses owner-only files, atomic replacement, a last-known-good
  backup, schema migration, and corrupt-file quarantine.
- Diagnostic logs are redacted, size-limited, and written with owner-only
  permissions.
- Private SkyLight symbols are resolved at runtime. When they are missing,
  window listing and focus fall back to public Accessibility APIs.
- The app is intentionally not sandboxed so it can read and move windows.

The standalone test executable combines focused security-boundary checks with
the placement and settings regression harness, without requiring XCTest to be
installed.
