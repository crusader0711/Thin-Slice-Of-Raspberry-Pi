#!/usr/bin/env bash
# Static analysis for all shell in the repo. shellcheck if present, bash -n floor.
set -euo pipefail
cd "$(dirname "$0")/.."
mapfile -t SH < <(find src scripts hooks examples tests -type f -name '*.sh')
rc=0
for f in "${SH[@]}"; do
  bash -n "$f" || rc=1
  if command -v shellcheck >/dev/null; then shellcheck -S warning "$f" || rc=1; fi
done
# Placeholder hygiene: no concrete RFC1918 addresses committed
if grep -rnE '([0-9]{1,3}\.){3}[0-9]{1,3}' README.md docs/ src/ config/ examples/ --include='*' | grep -v '0\.0\.0\.0'; then
  echo "FAIL: concrete IP address committed — use <PLACEHOLDERS>"; rc=1
fi
exit $rc
