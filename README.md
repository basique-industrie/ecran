<p align="center">
  <img src="docs/assets/app-icon.png" width="128" alt="Ecran application icon">
</p>

<h1 align="center">Ecran</h1>

<p align="center">
  Switch, snap, and place every window on your Mac.
</p>

Ecran is a menu-bar window manager and list-only switcher. It combines
Lineup’s same-app and app switchers with Rectangle’s keyboard placements,
snap areas, and multi-window arrange actions. There is no Dock icon.
Nothing leaves this machine.

[Download 0.1.0-beta.1](https://github.com/basique-industrie/ecran/releases)
for macOS 26 (universal).
[CI](https://github.com/basique-industrie/ecran/actions/workflows/ci.yml)
· [Releases](https://github.com/basique-industrie/ecran/releases)

## Features

- **Same-app switcher** — `⌘ + \`` lists the front app’s windows, with project
  names taken from the title
- **App switcher** — `⌘ + Tab` can replace the system Command-Tab hold
- **List-only overlay** — arrow keys, Enter, Esc, and 1–9; icon, initials, or
  live preview rows
- **Spaces** — windows from every desktop, including minimized Dock windows;
  stay visible across desktop slides
- **Keyboard placement** — halves, thirds, fourths, sixths, eighths, ninths,
  twelfths, and sixteenths; maximize, almost maximize, center, restore, and
  specified size
- **Displays** — next and previous display, jump to displays 1–9, treat
  screens as one canvas, or follow the cursor
- **Arrange** — tile, cascade, reverse, and a reserved todo sidebar
- **Drag snap** — edge and corner zones with a footprint, unsnap-on-drag,
  sixths, thirds cycling, haptics, and a Mission Control guard
- **Cooperative corners** — the neighboring window fills the leftover band
- **Window controls** — title-bar double-click to maximize or restore, and an
  optional green zoom-button override
- **Ignore an app** — placement shortcuts and snap skip it; the switcher stays
  live
- **Shortcuts** — record, clear, and import recommended or Spectacle presets;
  export and import JSON from Settings
- **Window titles** — per-app extraction for the switcher list
- **Menu bar** — launch at login, hide the icon, extra sizes, and URL actions
  such as `ecran://execute-action?name=left-half`. Ignore-list URL tasks
  prompt first. Window-action URLs can optionally prompt from Settings.

Recommended shortcuts are ⌃⌥ arrows for halves, ⌃⌥ U/I/J/K for corners, and
⌃⌥ Return to maximize.

## Install

1. [Download the latest release](https://github.com/basique-industrie/ecran/releases).
2. Unzip it and move **Ecran.app** to **Applications**.
3. Open **Ecran**. Settings explains **Accessibility** (required) and
   **Screen Recording** (optional live previews). Grant there — Ecran
   opens the matching System Settings pane so you can flip the toggle.

The notarized zip is signed. A local `scripts/package.sh` build is **Ecran Dev**:
a different bundle ID, isolated settings, and a stable local signature so
Accessibility and Screen Recording survive rebuilds next to `/Applications/Ecran.app`.

## Build from source

macOS 26 SDK and a Swift 6.2 toolchain:

```bash
./scripts/run.sh
```

That packages and opens **Ecran Dev** (`dist/Ecran Dev.app`). Leave the GitHub
**Ecran.app** in Applications if you want both running.

| Command | Purpose |
| --- | --- |
| `./scripts/run.sh` | Package and open Ecran Dev |
| `./scripts/run.sh --open-settings` | Open Settings on launch |
| `./scripts/run.sh --reset-permissions` | Drop Dev Accessibility / Screen Recording grants |
| `swift test` | Not used; the suite is a standalone executable |
| `./scripts/test.sh` | Regression and security suites |
| `./scripts/check-public-release.sh` | Public-release hygiene |
| `./scripts/package.sh` | Signed `dist/Ecran Dev.app` (TCC persists) |
| `./scripts/package.sh --shipped` | Signed `dist/Ecran.app` |
| `./scripts/release.sh` | Signed, notarized zip from a matching tag |

## Local data

| Data | Shipped Ecran | Ecran Dev |
| --- | --- | --- |
| Settings | `~/.ecran/settings.json` | `~/.ecran-dev/settings.json` |
| Redacted logs | `~/Library/Logs/Ecran/` | `~/Library/Logs/Ecran-Dev/` |

Network activity is none. Accessibility is required. Screen Recording is
optional and used only for live switcher previews.

## Documentation

| Document | Audience and scope |
| --- | --- |
| [Architecture](ARCHITECTURE.md) | Module boundaries and reliability controls |
| [Release](docs/RELEASE.md) | Versioning, signing, notarization, and publication |
| [Contributing](CONTRIBUTING.md) | Change workflow and documentation expectations |
| [Privacy](PRIVACY.md) | Data processed on the Mac and required-reason APIs |
| [Security](SECURITY.md) | Trust boundaries and reporting |
| [Third-party notices](THIRD_PARTY_NOTICES.md) | Lineup, Rectangle, and generated artwork |

## License and trademarks

Code is available under the [MIT License](LICENSE). Lineup and Rectangle remain
subject to their own MIT notices. The name Ecran is used as a product name for
this window manager; it does not imply affiliation with those projects.
