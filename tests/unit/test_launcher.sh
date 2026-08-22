#!/usr/bin/env bash
# Unit: kiosk-browser.sh resolves the correct URL and flag set per mode.
set -euo pipefail
cd "$(dirname "$0")/../.."
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
fail=0

run_launcher () { # $1 fixture, $2 get-login mock output (optional)
  sed -e "s|/etc/kiosk.conf|$1|" \
      -e "s|^exec chromium-browser|echo CMD: chromium-browser|" \
      -e "s|/usr/local/bin/get-login-url.sh|echo ${2:-UNUSED}|" \
      src/pi/kiosk-browser.sh > "$TMP/launch.sh"
  bash "$TMP/launch.sh"
}

OUT="$(run_launcher tests/fixtures/kiosk.conf.cast)"
echo "$OUT" | grep -q -- '--kiosk https://server.test:9443/#/cast/testkey' || { echo "FAIL cast URL"; fail=1; }
echo "$OUT" | grep -q -- '--incognito' || { echo "FAIL cast incognito"; fail=1; }
echo "$OUT" | grep -q -- '--ignore-certificate-errors' || { echo "FAIL cast IGNORE_TLS flag"; fail=1; }

OUT="$(run_launcher tests/fixtures/kiosk.conf.persistent 'https://server.test:9443/#/connect/login/dash/MOCK')"
echo "$OUT" | grep -q -- '--kiosk https://server.test:9443/#/connect/login/dash/MOCK' || { echo "FAIL persistent URL"; fail=1; }
echo "$OUT" | grep -q -- '--user-data-dir=' || { echo "FAIL persistent profile dir"; fail=1; }
echo "$OUT" | grep -q -- '--incognito' && { echo "FAIL persistent must not be incognito"; fail=1; }
echo "$OUT" | grep -q -- '--ignore-certificate-errors' && { echo "FAIL IGNORE_TLS=0 must not add flag"; fail=1; }

[[ $fail -eq 0 ]] && echo "PASS test_launcher" || exit 1
