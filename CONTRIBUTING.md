# Contributing

Solo-maintained OFS project; external PRs welcome but reviewed strictly.

- **Branching:** `main` is protected. Branches: `feat/<slug>`, `fix/<slug>`,
  `docs/<slug>`. Squash-merge only.
- **Commits:** Conventional Commits (`feat:`, `fix:`, `docs:`, `test:`,
  `chore:`). CHANGELOG generation depends on it.
- **Before pushing:** `make lint test` must pass; hooks installed via
  `make setup` run the same checks plus a secret scan.
- **Hygiene rules:** no concrete IPs/hostnames/keys (placeholders only); no
  dates outside the README Last Updated badge; ADRs are immutable once
  Accepted — supersede, don't edit.
- **Versioning:** SemVer. Bump in `CHANGELOG.md` under `[Unreleased]` → cut
  with `make release`.

## Ideas / backlog
- Record ideas for consideration in `docs/BACKLOG.md` (IDs `BL.NN`, status `proposed`, priority `5` high to `1` low).
- Optionally open an issue using `.github/ISSUE_TEMPLATE/idea.yml` (label `idea`); opening an issue does not assign a `BL.NN` ID.
- Idea text must contain no personal details, credentials, or private household/health/school/finance/location information.
