# Release process

Versions follow Semantic Versioning:

| Form | Example | Where it appears |
| --- | --- | --- |
| Package version | `0.1.0-beta.1` | `CFBundleShortVersionString`, About (`Version 0.1.0-beta.1 (1)`), GitHub release title |
| Git tag | `v0.1.0-beta.1` | `git tag`, workflow trigger |
| Build | `1` | `CFBundleVersion`, zip name, About parentheses |

Allowed package versions are `X.Y.Z` or `X.Y.Z-(alpha|beta|rc).N`. No leading
zeros, no `+` build metadata, no other prerelease words. Tags add the `v`; the
string a person reads never has one. `CFBundleVersion` is a positive integer and
only ever increases for `com.jean.ecran`.

A version with a channel suffix is a prerelease. `scripts/publish.sh` marks the
GitHub release as such.

## One-time setup

1. Install the macOS 26 SDK and a Swift 6.2 toolchain.
2. Install a Developer ID Application certificate.
3. Store App Store Connect notarization credentials in a keychain profile:

   ```bash
   xcrun notarytool store-credentials ecran \
     --key AuthKey_XXXX.p8 --key-id KEY_ID --issuer ISSUER
   ```

   CI uses the same App Store Connect key and Developer ID certificate as
   the other Basique Industrie macOS apps, under the `release` environment
   secrets:

   - `APPLE_DEVELOPER_ID_APPLICATION_P12`
   - `APPLE_DEVELOPER_ID_PASSWORD`
   - `APPLE_NOTARY_KEY_ID`
   - `APPLE_NOTARY_KEY_ISSUER`
   - `APPLE_NOTARY_KEY_P8`

   GitHub never returns secret values through `gh`. Export the five values
   locally, then run `./scripts/set-release-secrets.sh`. Do not copy
   `SPARKLE_PRIVATE_KEY`; Ecran does not ship Sparkle.

4. Rewrite any private `.local` author email addresses before the repository's
   first public push. Do not rewrite shared public history afterward.

## Prepare

1. Move entries from `CHANGELOG.md`'s Unreleased section into a dated heading
   that matches `CFBundleShortVersionString` (for example
   `## 0.1.0-beta.1 - 2026-09-03`).
2. Keep `CFBundleShortVersionString`, `CFBundleVersion`, and the Git tag aligned.
3. Run:

   ```bash
   ./scripts/test.sh
   ./scripts/check-public-release.sh
   CHECK_HISTORY=1 ./scripts/check-public-release.sh
   ```

4. Commit the release, then create and check out the annotated tag matching the
   app version (for example `v0.1.0-beta.1`). The release script refuses an
   untagged or mismatched commit.

## Build, sign, and notarize

```bash
./scripts/release.sh
```

The script discovers the Developer ID identity, uses the `ecran` notary
profile, builds a universal hardened-runtime app, notarizes it, staples the
ticket, and writes a SHA-256 checksum. Override with `ECRAN_SIGN_IDENTITY` or
`NOTARY_PROFILE` if more than one identity is installed.

Pushing tag `v0.1.0-beta.1` runs the same script on the shared Basique
Industrie Mini (`m1-mac-mini`, labels `self-hosted` and `mac-mini`) after the
`release` environment is approved. `workflow_dispatch` with `dry_run` notarizes
without publishing. CI uses the same runner for `main` and same-repository
pull requests only; fork PRs are not scheduled on the Mini.

Test the stapled app on a clean macOS user account before publishing.

The ordinary `scripts/package.sh` command makes a locally signed **Ecran Dev**
build (`com.jean.ecran.dev`). It uses Apple Development when available, otherwise
a stable self-signed identity in `~/.ecran-dev/signing`, so Accessibility is not
asked again after every rebuild. It is not suitable for public distribution and
does not replace a notarized `Ecran.app`. `scripts/release.sh` always packages
the shipped identity (`com.jean.ecran`).
