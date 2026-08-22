#!/usr/bin/env bash
# Unit: every shell script in the repo parses.
set -euo pipefail
cd "$(dirname "$0")/../.."
find src scripts hooks examples -type f \( -name '*.sh' -o -name 'pre-commit' \) -print0 |
  xargs -0 -n1 bash -n
echo "PASS test_syntax"
