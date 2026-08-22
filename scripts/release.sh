#!/usr/bin/env bash
# Generate RELEASE_MANIFEST.json + SHA256SUMS from dist/. Never hand-edit either.
set -euo pipefail
cd "$(dirname "$0")/.."
./scripts/build.sh
VERSION="$(grep -m1 -oE '\[[0-9]+\.[0-9]+\.[0-9]+\]' CHANGELOG.md | tr -d '[]')"
COMMIT="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
RELEASED="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
{
  echo '{'
  echo "  \"name\": \"Thin-Slice-Of-Raspberry-Pi\","
  echo "  \"version\": \"${VERSION}\","
  echo "  \"released\": \"${RELEASED}\","
  echo "  \"git_commit\": \"${COMMIT}\","
  echo '  "artifacts": ['
  first=1
  for f in dist/*; do
    [[ $first -eq 1 ]] || echo ','
    first=0
    printf '    {"path": "%s", "sha256": "%s", "size_bytes": %s}' \
      "$f" "$(sha256sum "$f" | cut -d' ' -f1)" "$(stat -c%s "$f")"
  done
  echo ''
  echo '  ],'
  echo "  \"provenance\": {\"built_by\": \"${CI:+ci}${CI:-local}\", \"builder_id\": \"${GITHUB_ACTIONS:+github-actions}${GITHUB_ACTIONS:-$(hostname)}\"}"
  echo '}'
} > RELEASE_MANIFEST.json
sha256sum dist/* > SHA256SUMS
echo "release artifacts written: RELEASE_MANIFEST.json, SHA256SUMS"
