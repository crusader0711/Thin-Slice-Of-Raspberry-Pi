#!/usr/bin/env bash
# Example: provision a kiosk bound to one child (state survives reboots).
# Prereqs: docs/01-server-setup.md §8 complete; run ON THE PI from the repo root.
sudo KASM_HOST="<SERVER_IP_OR_FQDN>:<PORT>" \
     KASM_USER_ID="<KASM_USER_UUID>" \
     KASM_API_KEY="<API_KEY>" \
     KASM_API_SECRET="<API_SECRET>" \
     IGNORE_TLS=1 \
     ./src/pi/provision.sh
