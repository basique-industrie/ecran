# Security policy

## Supported versions

Security fixes are applied to the latest release and the `main` branch. Older
builds are not supported.

## Reporting a vulnerability

Do not open a public issue for a vulnerability. Use GitHub's private
**Security advisories → Report a vulnerability** flow for this repository.
Include the affected version, reproduction steps, impact, and any suggested
mitigation. Please avoid including real access tokens, cookies, account data,
or unredacted logs.

You should receive an acknowledgement within seven days. A coordinated fix and
disclosure timeline will be proposed after the report is reproduced.

## Security model

Ecran is a local menu-bar utility, but it is intentionally not sandboxed:
it reads window metadata and can move or resize other applications' windows.
The app:

- stores preferences in an owner-only JSON file with atomic replacement and
  corrupt-file quarantine;
- redacts diagnostic logs and gives their directory and files owner-only
  permissions;
- uses Accessibility and, when available, SkyLight symbols only to enumerate
  and focus windows;
- does not include automatic update download or a telemetry endpoint.

Grant Accessibility only if you want Ecran to control windows. Screen
Recording is optional and used only for switcher previews.

## CI runners

CI, CodeQL, and Release run on a shared Basique Industrie Mac Mini. That
machine is not an ephemeral GitHub-hosted VM: it can see other org checkouts
and is also used to sign notarized builds.

- Fork pull requests do not run on the Mini. Same-repository branches and
  `main` still do.
- Outside collaborators need a maintainer to approve their workflow before
  Actions starts.
- Org runner access is limited to this repository. A new public repo in the
  org does not inherit the Mini.
