#!/bin/zsh
# Copy the Apple signing secrets into this repository's `release` environment.
set -euo pipefail

REPO="${REPO:-basique-industrie/ecran}"
SOURCE_REPO="${SOURCE_REPO:-basique-industrie/iles}"
ENV_NAME=release

required=(
  APPLE_DEVELOPER_ID_APPLICATION_P12
  APPLE_DEVELOPER_ID_PASSWORD
  APPLE_NOTARY_KEY_ID
  APPLE_NOTARY_KEY_ISSUER
  APPLE_NOTARY_KEY_P8
)

source_names="$(gh secret list --repo "$SOURCE_REPO" --env "$ENV_NAME" --json name -q '.[].name')"
for name in "${required[@]}"; do
  grep -qx "$name" <<<"$source_names" || {
    echo "$SOURCE_REPO $ENV_NAME is missing $name." >&2
    exit 1
  }
done

for name in "${required[@]}"; do
  [[ -n "${(P)name:-}" ]] || {
    echo "Export $name first (same value as $SOURCE_REPO $ENV_NAME). GitHub will not return it." >&2
    exit 1
  }
done

for name in "${required[@]}"; do
  printf '%s' "${(P)name}" | gh secret set "$name" --repo "$REPO" --env "$ENV_NAME"
  echo "Wrote $name"
done
