#!/usr/bin/env bash
# Mode-aware browser launcher (runs inside cage). Reads /etc/kiosk.conf.
#
#   persistent — fetch a per-user login URL via the Kasm API each boot;
#                Chromium uses a persistent local profile (keeps the Kasm auth
#                cookie as a secondary continuity layer). All meaningful state
#                (bookmarks, files, settings) lives server-side in the user's
#                Kasm persistent profile.
#   cast       — open the anonymous casting URL in incognito; factory-fresh
#                every boot.

source /etc/kiosk.conf

FLAGS=(
  --noerrdialogs
  --disable-infobars
  --no-first-run
  --disable-session-crashed-bubble
  --disable-translate
  --disable-pinch
  --overscroll-history-navigation=0
  --autoplay-policy=no-user-gesture-required
  --check-for-update-interval=31536000
  --ozone-platform=wayland
)
[[ "${IGNORE_TLS}" == "1" ]] && FLAGS+=(--ignore-certificate-errors)

if [[ "${MODE}" == "persistent" ]]; then
  URL="$(/usr/local/bin/get-login-url.sh)"
  FLAGS+=(--user-data-dir="${HOME}/.kiosk-profile")
else
  URL="https://${KASM_HOST}/#/cast/${CAST_KEY}"
  FLAGS+=(--incognito)
fi

exec chromium-browser --kiosk "${URL}" "${FLAGS[@]}"
