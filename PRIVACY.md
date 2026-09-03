# Privacy

Ecran is local-first. It contains no analytics SDK, advertising SDK,
tracking, crash-upload service, or telemetry endpoint.

## Data processed on your Mac

The app reads window titles, frames, Space membership, and running-application
identity so it can switch, move, and resize windows. Optional Screen Recording
access is used only for live switcher thumbnails. Data is not sent to the
Ecran project or its maintainers.

Non-secret preferences are stored in `~/.ecran/settings.json`. The local
**Ecran Dev** build uses `~/.ecran-dev/settings.json` instead. Redacted,
size-limited diagnostics are stored in `~/Library/Logs/Ecran/` or
`~/Library/Logs/Ecran-Dev/`; support logs leave the Mac only when you export
and share one yourself.

## Network requests

Ecran makes no network requests.

## Permissions

Accessibility permission is requested on first launch and is required to list
and control windows. Screen Recording is requested only if you choose the live
preview display style. Launch at Login is opt-in.

The bundled privacy manifest declares File Timestamp required-reason APIs used
for local settings-file change detection.

## Removing local data

Quit Ecran, remove `~/.ecran/`, and remove `~/Library/Logs/Ecran/`. For
Ecran Dev, use `~/.ecran-dev/` and `~/Library/Logs/Ecran-Dev/`.
