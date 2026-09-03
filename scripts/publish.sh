#!/bin/zsh
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
cd "$PROJECT_ROOT"

TAG="${1:?Usage: scripts/publish.sh vX.Y.Z}"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Sources/Ecran/Info.plist)"
BUILD="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' Sources/Ecran/Info.plist)"
ARCHIVE="$PROJECT_ROOT/dist/Ecran-$VERSION-$BUILD.zip"
CHECKSUM="$ARCHIVE.sha256"

[[ "$TAG" == "v$VERSION" ]] || {
  echo "Tag $TAG does not match CFBundleShortVersionString $VERSION." >&2
  exit 1
}
[[ -f "$ARCHIVE" && -f "$CHECKSUM" ]] || {
  echo "Missing $ARCHIVE or $CHECKSUM. Run scripts/release.sh first." >&2
  exit 1
}

NOTES="$(awk '
  $0 == "## Unreleased" { next }
  $0 ~ /^## / { if (found) exit; found=1 }
  found { print }
' CHANGELOG.md)"
[[ -n "$NOTES" ]] || NOTES="Ecran $VERSION."

create_flags=(--title "Ecran $VERSION" --notes "$NOTES")
if [[ "$VERSION" == *-* ]]; then
  create_flags+=(--prerelease)
fi

gh release create "$TAG" "${create_flags[@]}" "$ARCHIVE" "$CHECKSUM"
