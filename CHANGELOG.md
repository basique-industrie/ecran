# Changelog

Notable user-facing changes are documented here. Versions follow Semantic
Versioning: `X.Y.Z` or `X.Y.Z-(alpha|beta|rc).N`. The About pane and GitHub
release title show that string with no leading `v`. Tags add the `v`.

## Unreleased

## 0.1.0-beta.1 - 2026-09-03

### Added

- Combined Lineup same-app and app switchers with Rectangle window actions,
  snap areas, restore, multi-window arrange, URL commands, and JSON
  configuration import/export.
- Menu-bar accessory app with isolated **Ecran Dev** settings, redacted
  support logs, and Iles-style release automation.

### Changed

- Release notes describe Semantic Versioning without naming another project.
- Settings panes fill the window and use two columns, so the default size no
  longer leaves an empty gutter on the right.
- Settings tabs, permissions, switcher appearance, snap zones, and About are
  more visual.
- Settings tabs are a compact single-line bar instead of tall icon stacks.
- Settings tabs keep a fixed height when the window is resized; only the page
  below grows or shrinks.
- Settings tabs span the page: General sits on the left inset and About on
  the right.
- The app and window switcher lists use Iles-style icon wells, window stacks,
  and desktop glyphs instead of a text-only row.
- The switcher panel is a single rounded Spotlight-style overlay with a
  rounded selection row, instead of a square window behind rounded cards.

### Fixed

- A second launch with `--open-settings` now opens Settings on the running
  instance instead of exiting and dropping the flag.
- Restore-on-second-title-bar-click follows the Settings toggle. Importing a
  config (or a launch `EcranConfig.json`) applies hide-icon, green-button, and
  language side effects immediately.
- Export titles writes title configs only, so a titles file no longer includes
  shortcuts and ignore lists.
- The green zoom button re-enables after a system tap timeout and maximizes
  the window that was clicked, not whichever window happens to be focused.
- Accessibility values are read with conditional casts so a bad AX type no
  longer traps the process.
- A fast same-app switcher tap activates the next window instead of leaving
  the overlay stuck. Command-Tab replaces the same-app list instead of
  stacking the system switcher on top.
- Snap no longer treats 1pt AX jitter as a move, uses the dragged window for
  preserve-axis previews, clears a stale footprint during the Mission Control
  grace window, and skips floating windows. Cooperative corner resize no
  longer crushes a neighboring half and records that neighbor for Restore.
- Settings can be drag-snapped. Snapping now sees local mouse events and the
  window under the cursor, so Ecran’s own windows are not skipped. Local
  drags no longer read every window number, which crashed Settings on open.
- Switcher hotkey menus show one chevron per key instead of the system
  indicator stacked on the custom arrow.
- Snap haptic feedback clicks when a zone lights up, and once when you turn
  the setting on, instead of only after the window is dropped.
- Stay-visible-across-desktops now changes the switcher panel’s Space
  behavior. Cooperative corner resize fills the neighboring band. Language
  writes the process language preference.
- Shortcut chips show the full chord, including arrow keys, instead of only
  the modifiers.
- The About mark draws the three window panes in the rounded square instead of
  embedding the macOS app icon, so it no longer looks like a double border.
- The app switcher lists only Dock-visible regular apps, matching Command-Tab,
  instead of also including menu-bar accessories that happen to have a layer.
- Command-Tab no longer tears down its event tap when the switcher opens or
  the front app changes. The tap is re-enabled after a system timeout, and
  releasing Command activates the selected app.
- The app switcher lists apps with a single Accessibility call per process
  instead of a 100 ms Space scan, so it opens immediately.
- The app switcher uses a fixed 600×400 list panel so every running app is
  visible and the overlay stays horizontally centered.
- Window moves now set size, then position, then size again and record the
  frame macOS actually applied, matching Rectangle’s resize path.
- Ignore-app now disables only placement shortcuts and drag-snap, so the
  switcher still works in an ignored app. Menu, URL, title-bar, and green
  button actions still run.
- Opening the switcher suspends placement hotkeys and snap so the two
  feature sets cannot fight over the same gesture.
- Tile/cascade-all no longer duplicates windows once per display.
- Todo mode now reserves the sidebar for other placements and pins the
  todo window to the strip.
- Switcher display style, color, header, number keys, follow-display, and
  modifier-release now apply at runtime.
