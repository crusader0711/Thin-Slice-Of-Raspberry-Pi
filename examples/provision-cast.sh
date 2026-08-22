#!/usr/bin/env bash
# Example: provision a stateless shared kiosk (factory-fresh every boot).
# Prereqs: docs/01-server-setup.md §4 casting config; run ON THE PI from the repo root.
sudo KASM_HOST="<SERVER_IP_OR_FQDN>:<PORT>" \
     CAST_KEY="<CAST_KEY>" \
     IGNORE_TLS=1 \
     ./src/pi/provision.sh
