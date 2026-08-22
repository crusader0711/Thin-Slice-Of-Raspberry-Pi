#!/usr/bin/env bash
# Developer workstation setup (NOT the Pi provisioner — that is src/pi/provision.sh).
set -euo pipefail
command -v shellcheck >/dev/null || echo "note: shellcheck not found — lint will fall back to bash -n"
command -v gitleaks   >/dev/null || echo "note: gitleaks not found — secret scan in pre-commit will be skipped"
echo "setup complete"
