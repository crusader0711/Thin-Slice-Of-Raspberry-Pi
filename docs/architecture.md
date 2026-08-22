# Architecture

System boundary, block diagram, and data flow for the kiosk system. Decision
history lives in [`docs/decisions/`](decisions/); numbered walkthroughs in
[`01-server-setup.md`](01-server-setup.md) and [`02-pi-setup.md`](02-pi-setup.md).

```text
┌─────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│  RASPBERRY PI    │────▶│  KASM WORKSPACES │────▶│  SESSION          │
│  THIN CLIENT     │     │  ORCHESTRATION   │     │  CONTAINER        │
│  cage + Chromium │◀────│  (UNRAID/Docker) │◀────│  (filtered        │
│  --kiosk         │     │  API + Casting   │     │   browser)        │
└─────────────────┘     └──────────────────┘     └──────────────────┘
        │                        │                        │
   HTTPS 443 only         DinD container mgmt      KasmVNC/WebSocket
   (kiosk VLAN,           Web Filter Policy        video/input stream
    egress-restricted)    persistent profiles      back to client
```

## Boot / data flow (persistent mode)

1. systemd `kiosk.service` (tty1, `Restart=always`) starts after
   `network-online.target`.
2. `ExecStartPre` → `wait-for-kasm.sh` blocks until `GET /api/__healthcheck`
   answers (server race + link race solved in one gate).
3. `kiosk-browser.sh` → `get-login-url.sh` → `POST /api/public/get_login`
   (key scoped to `Users Auth Session`) → per-user login URL.
4. cage launches Chromium `--kiosk <url>`; group setting auto-launches her
   default workspace; the workspace mounts `/profiles/{username}`.
5. Session stop/reboot: reattach to the running container inside the idle
   window (same tabs); otherwise fresh container + profile restore
   (same bookmarks/files/settings).

Cast mode replaces steps 3–4 with the anonymous casting URL in incognito.

## Interface table

| Layer | Component | Interface / Protocol | Constraint / failure mode |
|:------|:----------|:---------------------|:--------------------------|
| Client | Pi OS Lite 64-bit, cage, Chromium | HDMI, USB HID, Ethernet | Stateless except `/etc/kiosk.conf` (0600) |
| Boot gate | wait-for-kasm.sh | HTTPS healthcheck | Timeout → systemd retry loop, indefinitely |
| Auth (persistent) | get-login-url.sh | POST /api/public/get_login | API failure → login-page fallback, never dead screen |
| Entry (cast) | casting URL | /#/cast/<key> | IP-restricted; session caps bound RAM blast radius |
| Orchestration | Kasm 1.18.x single-container (DinD) | Docker on UNRAID | Pinned tag; ~2 GB RAM + 2 cores per session |
| State | /profiles/{username} | bind mount | Backup-critical share (risk R8) |
| Network | kiosk VLAN → Kasm:443 only | firewall | All other egress denied |
