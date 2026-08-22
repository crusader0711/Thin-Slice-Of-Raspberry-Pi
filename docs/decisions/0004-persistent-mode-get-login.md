# ADR-0004: Per-child persistent mode via Developer API `get_login`

**Status:** Accepted — supersedes ADR-0003 as the default mode

**Context:** The owner requires each kiosk to be one child's computer:
bookmarks, files, and settings must survive reboots and session stops.
Anonymous casting cannot provide this (ephemeral users by definition), and
manual login violates the zero-touch requirement.

**Decision:** Bind each kiosk to a Kasm user. At boot, the kiosk calls
`POST /api/public/get_login` with an API key scoped to `Users Auth Session`
only, and opens the returned no-password login URL. The user's group
auto-launches the default workspace; the workspace uses a persistent profile at
`/profiles/{username}`. On API failure the launcher degrades to the Kasm login
page rather than a dead screen.

**Consequences:** State survives reboots (session reattach inside the idle
window; profile restore outside it). Trade-offs accepted: one credential now
rests on each SD card (mitigations: least-privilege scope, per-kiosk keys,
individual revocation — risk R7), and the `/profiles` share becomes
backup-critical (risk R8).
