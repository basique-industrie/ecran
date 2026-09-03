#!/bin/zsh
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
cd "$PROJECT_ROOT"

CONFIGURATION="${CONFIGURATION:-release}"
VARIANT="${ECRAN_VARIANT:-dev}"
PRODUCT_NAME="Ecran"

for arg in "$@"; do
  case "$arg" in
    --dev) VARIANT="dev" ;;
    --shipped) VARIANT="shipped" ;;
    *)
      echo "Unknown argument: $arg" >&2
      echo "Usage: $0 [--dev|--shipped]" >&2
      exit 1
      ;;
  esac
done

case "$VARIANT" in
  dev)
    APP_NAME="Ecran Dev"
    IDENTIFIER="com.jean.ecran.dev"
    EXECUTABLE_NAME="EcranDev"
    ;;
  shipped)
    APP_NAME="Ecran"
    IDENTIFIER="com.jean.ecran"
    EXECUTABLE_NAME="Ecran"
    ;;
  *)
    echo "Unknown ECRAN_VARIANT: $VARIANT (use dev or shipped)" >&2
    exit 1
    ;;
esac

FINAL_APP="$PROJECT_ROOT/dist/${APP_NAME}.app"
ENTITLEMENTS="$PROJECT_ROOT/Sources/Ecran/Ecran.entitlements"
ICON="$PROJECT_ROOT/Sources/Ecran/Resources/Ecran.icns"
STAGE_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/Ecran-package.XXXXXX")"
STAGED_APP="$STAGE_ROOT/${APP_NAME}.app"

cleanup() {
  [[ "$STAGE_ROOT" == *"/Ecran-package."* ]] && /bin/rm -rf "$STAGE_ROOT"
}
trap cleanup EXIT

if [[ -n "${PREBUILT_BINARY:-}" ]]; then
  BINARY="$PREBUILT_BINARY"
else
  echo "Building ${PRODUCT_NAME} (${CONFIGURATION}, ${VARIANT})..."
  swift build -c "$CONFIGURATION" --product "$PRODUCT_NAME"
  BINARY_DIRECTORY="$(swift build -c "$CONFIGURATION" --show-bin-path)"
  BINARY="$BINARY_DIRECTORY/$PRODUCT_NAME"
fi

[[ -x "$BINARY" ]] || { echo "Missing executable: $BINARY" >&2; exit 1; }
[[ -f "$ICON" ]] || { echo "Missing application icon: $ICON" >&2; exit 1; }

mkdir -p "$STAGED_APP/Contents/MacOS" "$STAGED_APP/Contents/Resources"
install -m 0755 "$BINARY" "$STAGED_APP/Contents/MacOS/$EXECUTABLE_NAME"
install -m 0644 Sources/Ecran/Info.plist "$STAGED_APP/Contents/Info.plist"
plutil -replace CFBundleIdentifier -string "$IDENTIFIER" "$STAGED_APP/Contents/Info.plist"
plutil -replace CFBundleName -string "$APP_NAME" "$STAGED_APP/Contents/Info.plist"
plutil -replace CFBundleDisplayName -string "$APP_NAME" "$STAGED_APP/Contents/Info.plist"
plutil -replace CFBundleExecutable -string "$EXECUTABLE_NAME" "$STAGED_APP/Contents/Info.plist"
install -m 0644 "$ICON" "$STAGED_APP/Contents/Resources/Ecran.icns"
install -m 0644 Sources/Ecran/Resources/PrivacyInfo.xcprivacy "$STAGED_APP/Contents/Resources/PrivacyInfo.xcprivacy"
install -m 0644 LICENSE "$STAGED_APP/Contents/Resources/LICENSE.txt"
install -m 0644 THIRD_PARTY_NOTICES.md "$STAGED_APP/Contents/Resources/THIRD_PARTY_NOTICES.md"
printf 'APPL????' > "$STAGED_APP/Contents/PkgInfo"

BUNDLED_RESOURCES="$STAGED_APP/Contents/Resources/Ecran_EcranCore.bundle"
mkdir -p "$BUNDLED_RESOURCES"
for resource in Sources/Ecran/Resources/*; do
  [[ -f "$resource" ]] || continue
  case "${resource:t}" in
    PrivacyInfo.xcprivacy|Ecran.icns|EcranAppIcon.png) continue ;;
  esac
  install -m 0644 "$resource" "$BUNDLED_RESOURCES/${resource:t}"
done
if [[ -d Sources/Ecran/Resources/Licenses ]]; then
  setopt NULL_GLOB
  for license in Sources/Ecran/Resources/Licenses/*; do
    [[ -f "$license" ]] || continue
    install -m 0644 "$license" "$BUNDLED_RESOURCES/${license:t}"
  done
  unsetopt NULL_GLOB
fi

if [[ -z "${SIGNING_IDENTITY:-}" ]]; then
  SIGNING_IDENTITY="$("$PROJECT_ROOT/scripts/sign-identity" --local || true)"
fi
SIGNATURE="${SIGNING_IDENTITY:--}"
SIGN_ARGUMENTS=(--force --sign "$SIGNATURE" --entitlements "$ENTITLEMENTS" --identifier "$IDENTIFIER")
if [[ "$SIGNATURE" != "-" ]]; then
  SIGN_ARGUMENTS+=(--options runtime)
  if [[ "${SIGN_TIMESTAMP:-}" == "1" ]]; then
    SIGN_ARGUMENTS+=(--timestamp)
  fi
  echo "Signing with $SIGNATURE"
else
  echo "Using an ad-hoc signature; macOS will ask for Accessibility after every rebuild." >&2
fi
codesign "${SIGN_ARGUMENTS[@]}" "$STAGED_APP"
codesign --verify --deep --strict "$STAGED_APP"

mkdir -p "$PROJECT_ROOT/dist"
PREVIOUS_APP="$STAGE_ROOT/previous.app"
if [[ -e "$FINAL_APP" ]]; then
  mv "$FINAL_APP" "$PREVIOUS_APP"
fi
if ! mv "$STAGED_APP" "$FINAL_APP"; then
  [[ -e "$PREVIOUS_APP" ]] && mv "$PREVIOUS_APP" "$FINAL_APP"
  exit 1
fi

LSREG="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
if [[ -x "$LSREG" ]]; then
  "$LSREG" -f "$FINAL_APP" >/dev/null 2>&1 || true
fi

echo "Packaged $FINAL_APP ($IDENTIFIER)"
