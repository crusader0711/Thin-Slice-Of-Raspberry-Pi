#!/usr/bin/env bash
# Build a distributable tarball of the deployable client (src/pi + config example).
set -euo pipefail
cd "$(dirname "$0")/.."
VERSION="$(grep -m1 -oE '\[[0-9]+\.[0-9]+\.[0-9]+\]' CHANGELOG.md | tr -d '[]' || echo 0.0.0)"
mkdir -p dist
tar -czf "dist/thin-slice-${VERSION}.tar.gz" src/pi config/kiosk.conf.example
echo "built dist/thin-slice-${VERSION}.tar.gz"
