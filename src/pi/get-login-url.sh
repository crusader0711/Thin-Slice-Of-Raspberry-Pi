#!/usr/bin/env bash
# Persistent mode: obtain a no-password login URL for this kiosk's bound user
# via Kasm's Developer API (POST /api/public/get_login, permission
# "Users Auth Session"). Prints the URL on stdout.
#
# Fallback: if the API call fails (bad key, permission missing, transient
# error), print the Kasm base URL so the kiosk lands on the login page instead
# of a dead screen — degraded but recoverable by an adult.

source /etc/kiosk.conf

RESP="$(curl -ks --max-time 10 \
  -X POST "https://${KASM_HOST}/api/public/get_login" \
  -H 'Content-Type: application/json' \
  -d "{\"api_key\":\"${KASM_API_KEY}\",\"api_key_secret\":\"${KASM_API_SECRET}\",\"target_user\":{\"user_id\":\"${KASM_USER_ID}\"}}" \
  || true)"

URL="$(printf '%s' "${RESP}" | jq -r '.url // empty' 2>/dev/null || true)"

if [[ -n "${URL}" ]]; then
  printf '%s\n' "${URL}"
else
  logger -t kiosk "get_login failed; falling back to base URL. Response: ${RESP:0:200}"
  printf 'https://%s/\n' "${KASM_HOST}"
fi
