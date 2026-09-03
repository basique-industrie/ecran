# Contributing

Thanks for helping improve Ecran.

## Before opening a change

- Search existing issues and keep each pull request focused.
- Discuss large behavior, persistence-schema, security-boundary, or visual-
  language changes before implementation.
- Never commit credentials, user paths, account data, build products, or
  unredacted diagnostic logs.
- Confirm that any new asset can be redistributed and document its source and
  license in `THIRD_PARTY_NOTICES.md`.
- Fork pull requests do not run on the org Mini. A maintainer will run CI
  from a same-repository branch before merge.

## Development

Ecran requires macOS 26 and the matching Swift toolchain.

```bash
swift build --product Ecran
./scripts/test.sh
./scripts/check-public-release.sh
```

Keep domain policy in `Sources/Domain`, rect math in `Sources/WindowGeometry`,
OS adapters in `Sources/Infrastructure`, and SwiftUI/runtime composition in
`Sources/Ecran`. Prefer small focused types, structured concurrency, and tests
for failure paths as well as successful placements.

## Pull requests

Describe the user-visible outcome, security/privacy impact, verification, and
screenshots for UI changes. Update `CHANGELOG.md` under **Unreleased**. By
submitting a contribution, you agree that it is licensed under the MIT License.
