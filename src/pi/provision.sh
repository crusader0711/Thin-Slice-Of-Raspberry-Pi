#!/usr/bin/env bash
#
# Thin-Slice-Of-Raspberry-Pi provisioner — idempotent; safe to re-run.
#
# Two modes, auto-selected by which variables you provide:
#
#   PERSISTENT (per-child kiosk — state survives reboots and session stops):
#     sudo KASM_HOST="<SERVER_IP_OR_FQDN>:<PORT>" \
#          KASM_USER_ID="<KASM_USER_UUID>" \
#          KASM_API_KEY="<API_KEY>" KASM_API_SECRET="<API_SECRET>" \
#          [IGNORE_TLS=1] ./provision.sh
#
#   CAST (stateless kiosk — factory-fresh every boot):
#     sudo KASM_HOST="<SERVER_IP_OR_FQDN>:<PORT>" CAST_KEY="<CAST_KEY>" \
#          [IGNORE_TLS=1] ./provision.sh
#
# Optional for either mode:
#   CA_CERT=/path/to/<CA_ROOT>.crt   install an internal CA into the trust store
#   NO_REBOOT=1                      skip the final reboot
#
# All runtime settings land in /etc/kiosk.conf (mode 600, owner kiosk).
# Re-run with new variables any time to reconfigure.

set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "Run as root (sudo)."; exit 1; }
: "${KASM_HOST:?Set KASM_HOST, e.g. KASM_HOST=<SERVER_IP>:<PORT>}"

if [[ -n "${KASM_USER_ID:-}" ]]; then
  MODE="persistent"
  : "${KASM_API_KEY:?Persistent mode needs KASM_API_KEY}"
  : "${KASM_API_SECRET:?Persistent mode needs KASM_API_SECRET}"
elif [[ -n "${CAST_KEY:-}" ]]; then
  MODE="cast"
else
  echo "Provide either KASM_USER_ID (+API key/secret) for persistent mode, or CAST_KEY for cast mode." >&2
  exit 1
fi
IGNORE_TLS="${IGNORE_TLS:-0}"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Thin-Slice-Of-Raspberry-Pi provisioner"
echo "    Mode:       ${MODE}"
echo "    Kasm host:  ${KASM_HOST}"
echo "    IGNORE_TLS: ${IGNORE_TLS}"

# ---------------------------------------------------------------- packages ---
echo "==> Installing packages"
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y cage chromium-browser seatd curl jq

# ------------------------------------------------------------- kiosk user ----
echo "==> Creating kiosk user"
id kiosk &>/dev/null || useradd -m kiosk
usermod -aG video,render,input,audio kiosk

# ----------------------------------------------------------- optional CA -----
if [[ -n "${CA_CERT:-}" ]]; then
  echo "==> Installing CA certificate into system trust store"
  install -m 0644 "${CA_CERT}" /usr/local/share/ca-certificates/kiosk-ca.crt
  update-ca-certificates
fi

# ---------------------------------------------------------- runtime config ---
echo "==> Writing /etc/kiosk.conf"
cat > /etc/kiosk.conf <<EOF
# Thin-Slice-Of-Raspberry-Pi runtime config — written by provision.sh
KASM_HOST="${KASM_HOST}"
MODE="${MODE}"
CAST_KEY="${CAST_KEY:-}"
KASM_USER_ID="${KASM_USER_ID:-}"
KASM_API_KEY="${KASM_API_KEY:-}"
KASM_API_SECRET="${KASM_API_SECRET:-}"
IGNORE_TLS="${IGNORE_TLS}"
EOF
chown kiosk:kiosk /etc/kiosk.conf
chmod 0600 /etc/kiosk.conf

# ------------------------------------------------------------- scripts -------
echo "==> Installing kiosk scripts"
install -m 0755 "${REPO_DIR}/wait-for-kasm.sh"   /usr/local/bin/wait-for-kasm.sh
install -m 0755 "${REPO_DIR}/get-login-url.sh"   /usr/local/bin/get-login-url.sh
install -m 0755 "${REPO_DIR}/kiosk-browser.sh"   /usr/local/bin/kiosk-browser.sh

# ---------------------------------------------------------- systemd unit -----
echo "==> Installing kiosk.service"
install -m 0644 "${REPO_DIR}/kiosk.service" /etc/systemd/system/kiosk.service
systemctl disable --now getty@tty1.service || true
systemctl enable --now seatd
systemctl daemon-reload
systemctl enable kiosk.service

# ----------------------------------------------------- kernel cmdline opts ---
echo "==> Configuring boot cmdline (no blanking, quiet boot)"
CMDLINE=/boot/firmware/cmdline.txt
[[ -f "$CMDLINE" ]] || CMDLINE=/boot/cmdline.txt   # older layouts
for opt in consoleblank=0 quiet loglevel=0 logo.nologo vt.global_cursor_default=0; do
  grep -qw "$opt" "$CMDLINE" || sed -i "s/\$/ $opt/" "$CMDLINE"
done

# ------------------------------------------------------- nightly self-heal ---
echo "==> Installing nightly reboot (04:00)"
cat > /etc/cron.d/kiosk-nightly-reboot <<'EOF'
# Thin-Slice-Of-Raspberry-Pi: nightly self-heal reboot.
# Safe in both modes: persistent state lives server-side, not on this Pi.
0 4 * * * root /sbin/reboot
EOF
chmod 0644 /etc/cron.d/kiosk-nightly-reboot

echo "==> Provisioning complete (${MODE} mode)."
if [[ "${NO_REBOOT:-0}" == "1" ]]; then
  echo "    NO_REBOOT=1 set — reboot manually to start the kiosk."
else
  echo "    Rebooting into kiosk mode in 5 s (Ctrl+C to abort)..."
  sleep 5
  reboot
fi
