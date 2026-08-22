# 02 — Raspberry Pi Setup

**Objective:** flash, provision, and verify a Pi that boots unattended into the
Kasm cast URL and recovers from crashes and network races on its own.

**Time:** ~30 min including the reboot.

---

## 1. Operating system expectations

- **Image:** Raspberry Pi OS **Lite**, **64-bit**, Debian 12 (Bookworm).
  - *Lite*, not Desktop: we don't want a desktop environment — `cage` replaces it.
  - *64-bit*: required package availability and tested path; Pi 3B+ and newer all
    support it.
- **Display stack:** Wayland via `cage`, a kiosk compositor that runs exactly one
  application fullscreen. There is no window manager, taskbar, or desktop.
- **Boot flow:**

```
firmware → kernel → systemd → network-online (Wants)
  → kiosk.service
      → ExecStartPre: wait-for-kasm.sh   (blocks until the server answers)
      → ExecStart:    cage → chromium --kiosk <cast URL>
      Restart=always                     (any crash → relaunch in 5 s)
```

- **No local state matters.** Browser runs `--incognito`; sessions live
  server-side. The SD card is disposable.

## 2. Flash

1. Raspberry Pi Imager → *Raspberry Pi OS Lite (64-bit)*.
2. Open customization (gear / Ctrl+Shift+X) and set:
   - Hostname: `kiosk-01`
   - **Enable SSH** (public-key auth)
   - Username: `admin` (or your choice — the provisioner creates a separate
     unprivileged `kiosk` user for the browser)
   - Wi-Fi credentials **only if Ethernet is impossible** — wired is strongly
     preferred
   - Locale / keyboard layout
3. Boot the Pi, find its IP (router/DHCP), SSH in.

## 3. Provision

```bash
sudo apt update && sudo apt install -y git
git clone https://github.com/Crusader0711/Thin-Slice-Of-Raspberry-Pi.git
cd Thin-Slice-Of-Raspberry-Pi

# PERSISTENT mode (per-child kiosk — state survives reboots; see docs/01 §8):
sudo KASM_HOST="<SERVER_IP_OR_FQDN>:<PORT>" \
     KASM_USER_ID="<KASM_USER_UUID>" \
     KASM_API_KEY="<API_KEY>" KASM_API_SECRET="<API_SECRET>" \
     IGNORE_TLS=1 ./src/pi/provision.sh

# CAST mode (stateless — factory-fresh every boot):
sudo KASM_HOST="<SERVER_IP_OR_FQDN>:<PORT>" CAST_KEY="<CAST_KEY>" IGNORE_TLS=1 ./src/pi/provision.sh

# Either mode — proper TLS instead of IGNORE_TLS, installing an internal CA root:
sudo KASM_HOST=... <mode vars> CA_CERT=/path/to/<CA_ROOT>.crt ./src/pi/provision.sh
```

The script is **idempotent** — rerun it any time to change the host/key or after
an OS update. It ends by rebooting into the kiosk.

## 4. What the provisioner does (annotated)

| Step | What | Why |
|---|---|---|
| Packages | `cage`, `chromium-browser`, `seatd`, `jq` | Compositor, browser, seat management, JSON parsing for the Kasm API |
| User | creates unprivileged `kiosk` in `video,render,input,audio` | Least privilege; browser never runs as root |
| `/etc/kiosk.conf` | mode + host + credentials, `0600`, owner `kiosk` | Single source of runtime config; re-run the provisioner to change it |
| `wait-for-kasm.sh` | curl-loop against Kasm's `/api/__healthcheck` (up to 2 min) | Solves the boot-before-network race. If it times out, systemd restarts the unit and it tries again — indefinitely. |
| `get-login-url.sh` | persistent mode only: `POST /api/public/get_login` → per-user login URL | The zero-touch auto-login; falls back to the Kasm login page if the API call fails |
| `kiosk-browser.sh` | Chromium with kiosk flags (see below) | Single place to tune behavior |
| `kiosk.service` | systemd unit owning tty1, `Restart=always` | Crash recovery + autostart; `getty@tty1` is disabled so nothing else claims the console |
| `/boot/firmware/cmdline.txt` | appends `consoleblank=0 quiet loglevel=0 logo.nologo vt.global_cursor_default=0` | No screen blanking, no boot text/cursor flash |
| Cron | `0 4 * * * /sbin/reboot` | Nightly self-heal: flushes leaked memory, dead WebSockets, expired sessions |

### Chromium flags used

| Flag | Purpose |
|---|---|
| `--kiosk <URL>` | Fullscreen, no chrome UI, no address bar |
| `--incognito` *(cast mode)* / `--user-data-dir` *(persistent mode)* | Cast: stateless client. Persistent: local profile keeps the Kasm auth cookie as a secondary continuity layer — real state lives server-side |
| `--noerrdialogs --disable-infobars --no-first-run --disable-session-crashed-bubble` | Suppress every dialog that could stall an unattended boot |
| `--disable-pinch --overscroll-history-navigation=0` | Kids can't zoom-wedge or swipe-navigate out of the session |
| `--autoplay-policy=no-user-gesture-required` | Kasm's audio stream plays without a click |
| `--check-for-update-interval=31536000` | No surprise update prompts |
| `--ozone-platform=wayland` | Native Wayland under cage |
| `--ignore-certificate-errors` | **Only with `IGNORE_TLS=1`** — see TLS section in doc 01 |

## 5. Verification

Run the failure-mode test matrix in
[runbooks/troubleshooting.md](runbooks/troubleshooting.md) — at minimum F1–F3 — before
handing the kiosk over.

## 6. Hardening after burn-in (recommended)

Once the kiosk has run happily for a week:

1. **Read-only root (overlay FS):** `sudo raspi-config` → *Performance* →
   *Overlay File System* → enable. The SD card becomes effectively immune to
   corruption from power-yanks (the dominant long-term Pi kiosk failure mode).
   Note: config changes require disabling the overlay first; do this last.
2. **Firewall (on your router/firewall, not the Pi):** kiosk VLAN → Kasm
   host:port **allow**; kiosk VLAN → anywhere else **deny**. After provisioning,
   the Pi needs nothing but the Kasm server (re-open apt access temporarily for
   updates).
3. **Updates cadence:** monthly `apt full-upgrade` via SSH (disable overlay
   first if enabled), then re-run `provision.sh` to reassert config.

## 7. Cloning additional kiosks

Flash a new card with hostname `kiosk-02`, run the same provisioner. Bump
*Limit Total Sessions* in the Kasm casting config accordingly. Alternatively,
image the first card after burn-in (`rpi-clone` or dd) and change only the
hostname.
