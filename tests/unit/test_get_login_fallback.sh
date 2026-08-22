#!/usr/bin/env bash
# Unit: get-login-url.sh falls back to base URL when the API is unreachable/invalid.
set -euo pipefail
cd "$(dirname "$0")/../.."
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
# Mock curl to simulate API failure; keep jq/logger real (logger may be absent: stub it)
cat > "$TMP/curl" <<'MOCK'
#!/usr/bin/env bash
exit 7
MOCK
cat > "$TMP/logger" <<'MOCK'
#!/usr/bin/env bash
exit 0
MOCK
chmod +x "$TMP/curl" "$TMP/logger"
sed "s|/etc/kiosk.conf|tests/fixtures/kiosk.conf.persistent|" src/pi/get-login-url.sh > "$TMP/gl.sh"
OUT="$(PATH="$TMP:$PATH" bash "$TMP/gl.sh")"
[[ "$OUT" == "https://server.test:9443/" ]] && echo "PASS test_get_login_fallback" || { echo "FAIL: got '$OUT'"; exit 1; }
