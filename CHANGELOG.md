# Changelog

Format: [Keep a Changelog](https://keepachangelog.com), SemVer. Per repo
policy, entries carry no dates — the README Last Updated badge is the single
date in this repository.

## [Unreleased]

- Added `BUILD.md`: linear Phase 0–7 build guide with gating checkpoints,
  including the Phase-2 API acceptance test that gates the Pi work.
- Restructured to OFS canonical repository template v1.0 (T1): `src/`,
  `config/` + schema, `tests/` (unit + fixtures), `scripts/` + Makefile verb
  interface, hooks, ADRs (0001–0004), runbooks, governance file set, CI.

## [2.1.0]

- Persistent per-child mode: API-based no-password login (`get_login`),
  server-side persistent profiles, session-reattach semantics, config-driven
  scripts (`/etc/kiosk.conf`), tests F9–F11, risks R7–R8.

## [2.0.0]

- Re-architected client on cage/Wayland with health-gated systemd unit;
  repo-based idempotent provisioner; Kasm pinned to 1.18.x; full docs and
  V&V matrix published.

## [1.x]

- Original desktop-autostart kiosk build (pre-repo); retired due to TLS
  interstitial and boot-race fragility.
