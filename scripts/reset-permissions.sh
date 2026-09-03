#!/bin/zsh
# Drop Ecran Dev Accessibility / Screen Recording grants so Grant can be
# tried again, and refresh Launch Services + Icon Services.
#
# System Settings caches the app mark from the first TCC row. After the
# icon changed, that list can keep showing the old Ecran Dev artwork until
# these rows are removed and the icon cache is flushed.
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
IDENTIFIER="${1:-com.jean.ecran.dev}"
APP="${ECRAN_DEV_APP:-$PROJECT_ROOT/dist/Ecran Dev.app}"
LSREG="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

if [[ "$IDENTIFIER" != *.dev ]]; then
  echo "Refusing to reset $IDENTIFIER. This script is only for Ecran Dev." >&2
  exit 1
fi

if pgrep -x EcranDev >/dev/null 2>&1; then
  killall EcranDev 2>/dev/null || true
  for _ in {1..40}; do
    if ! pgrep -x EcranDev >/dev/null 2>&1; then
      break
    fi
    sleep 0.05
  done
fi

tccutil reset Accessibility "$IDENTIFIER"
tccutil reset ScreenCapture "$IDENTIFIER"

if [[ -d "$APP" && -x "$LSREG" ]]; then
  "$LSREG" -f -R "$APP" >/dev/null 2>&1 || true
  touch "$APP"
fi
killall -u "$(id -un)" iconservicesagent >/dev/null 2>&1 || true

echo "Reset $IDENTIFIER. Grant Accessibility and Screen Recording again in Ecran Dev."
