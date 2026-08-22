#!/usr/bin/env bash
# Boot gate: block until the Kasm server answers.
# On timeout (~2 min) exit nonzero; systemd Restart=always retries forever,
# so the kiosk simply waits for the server, however long that takes.

source /etc/kiosk.conf

for _ in $(seq 1 60); do
  if curl -ks --max-time 3 "https://${KASM_HOST}/api/__healthcheck" >/dev/null; then
    exit 0
  fi
  sleep 2
done
exit 1
