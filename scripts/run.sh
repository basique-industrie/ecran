#!/bin/zsh
set -euo pipefail

cd "$(dirname "$0")/.."

CONFIGURATION="debug"
EXTRA_ARGS=()

for arg in "$@"; do
  case "$arg" in
    --release) CONFIGURATION="release" ;;
    --open-settings) EXTRA_ARGS+=("--open-settings") ;;
    *)
      echo "Unknown argument: $arg" >&2
      echo "Usage: $0 [--release] [--open-settings]" >&2
      exit 1
      ;;
  esac
done

CONFIGURATION="$CONFIGURATION" ./scripts/package.sh --dev

APP="dist/Ecran Dev.app"
if pgrep -x EcranDev >/dev/null 2>&1; then
  killall EcranDev 2>/dev/null || true
  for _ in {1..40}; do
    if ! pgrep -x EcranDev >/dev/null 2>&1; then
      break
    fi
    sleep 0.05
  done
  if pgrep -x EcranDev >/dev/null 2>&1; then
    echo "Ecran Dev did not exit; refusing to reactivate an older build." >&2
    exit 1
  fi
fi

echo "Launching Ecran Dev ($CONFIGURATION)..."
if [[ ${#EXTRA_ARGS[@]} -gt 0 ]]; then
  open "$APP" --args "${EXTRA_ARGS[@]}"
else
  open "$APP"
fi
