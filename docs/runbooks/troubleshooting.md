# 04 — Troubleshooting & Failure-Mode Test Matrix

## Acceptance tests (run these before handing over the kiosk)

| # | Test | Expected | Mechanism exercised |
|---|------|----------|---------------------|
| F1 | Cold boot, network up | Live session in <60 s, zero interaction | health gate → cast URL |
| F2 | Cold boot with **Ethernet unplugged**; plug in after ~1 min | Blank/black until link, then session appears unaided | `wait-for-kasm.sh` loop + systemd restart |
| F3 | `sudo pkill chromium` over SSH | Browser back in ~5 s | `Restart=always` |
| F4 | Child ends/abandons the session | Next reload/reboot yields a fresh session | anonymous casting = new session per visit |
| F5 | Restart the Kasm container mid-session | Canvas freezes; recovers on kiosk restart | acceptable; nightly reboot backstops |
| F6 | Mash Esc, Alt+F4, Ctrl+Alt+F1–F7 | Nothing escapes fullscreen | cage has no other surface; getty@tty1 disabled |
| F7 | Idle 30+ min | Screen stays on; session idle-disconnects per server policy | `consoleblank=0` |
| F8 | (cast mode) Open the cast URL on more devices than the session cap | Kasm limit message, server RAM protected | Casting session limits |
| F9 | (persistent) Reboot mid-use, return within idle window | Same session, same open tabs | Kasm session reattach |
| F10 | (persistent) Destroy her session from admin panel, reboot kiosk | Fresh session with her bookmarks/settings intact | Persistent profile restore |
| F11 | (persistent) Revoke/break the API key, reboot | Kiosk lands on the Kasm login page (degraded, adult-recoverable), not a dead screen | `get-login-url.sh` fallback |

## Diagnosis flow

```
Black screen forever?
├─ Can you SSH to the Pi? ── no ──► power/SD/network layer. Check PSU, link LEDs, DHCP lease.
│                                   Undervoltage: `dmesg | grep -i volt`
└─ yes
   ├─ systemctl status kiosk        ← is it cycling on ExecStartPre?
   │    └─ cycling = health check failing → server layer:
   │         curl -k https://<KASM_HOST>/api/__healthcheck   (from the Pi)
   │         ├─ connection refused → Kasm container down / wrong port
   │         ├─ timeout → routing/VLAN/firewall between kiosk and server
   │         └─ 200 but browser still fails → TLS (below)
   └─ journalctl -u kiosk -b        ← chromium/cage errors
```

## Known failure modes and fixes

### 1. Certificate interstitial ("Your connection is not private")
**Symptom:** kiosk stops at a Chromium warning page.
**Cause:** Kasm's self-signed cert, and the Pi wasn't provisioned with
`IGNORE_TLS=1` or a trusted CA.
**Fix:** re-run `provision.sh` with `IGNORE_TLS=1`, or install the CA root
(`CA_CERT=...`), or deploy a real certificate on the server (doc 01 §6).

### 2. Browser races the network at boot
**Symptom:** intermittent "site can't be reached" only on cold boots; fine after
manual refresh.
**Cause:** launch before link/DHCP/Kasm ready — should be impossible with the
health gate.
**Fix:** confirm `ExecStartPre` is present (`systemctl cat kiosk`); check that
`KASM_HOST` in `/usr/local/bin/wait-for-kasm.sh` matches the real host:port.

### 3. (Persistent mode) Kiosk lands on the Kasm login page instead of her session
**Cause:** the `get_login` API call failed — check on the Pi:
`/usr/local/bin/get-login-url.sh` (run as any user that can read
`/etc/kiosk.conf`) and `journalctl -t kiosk`.
**Usual culprits:** API key lacks the `Users Auth Session` permission; wrong
`KASM_USER_ID`; key revoked. Fix server-side or re-run `provision.sh` with
corrected values.
**Also check:** the child's group is missing the auto-launch-default-workspace
setting — then login *succeeds* but shows a dashboard; enable it in Group
settings (docs/01-server-setup.md §8.1).

### 4. Session-ended page sits on screen
**Symptom:** Kasm "session has ended / disconnected" page after idle timeout.
**Behavior:** by design — power cycle (or nightly reboot) mints a fresh session.
**Optional auto-recover:** shorten the loop by adding a systemd timer that
restarts `kiosk.service` at low-usage hours, or teach kids the power button.

### 5. No audio
Checklist: monitor volume → Kasm session volume (in-session) → on the Pi as the
`kiosk` user: `wpctl status` and confirm the HDMI sink is default. The
`--autoplay-policy` flag must be present (`systemctl cat kiosk` →
`kiosk-browser.sh`).

### 6. Sluggish video / choppy stream
Server-side first: `docker stats` on UNRAID — session container CPU pegged?
Raise workspace cores. Network second: Wi-Fi kiosk? Move to Ethernet. Pi-side
last: Pi 3 over Wi-Fi at 1080p60 is the worst case; cap the display at 1080p.

### 7. SD card corruption after power loss
**Symptom:** boot loops, fsck errors.
**Fix:** re-flash + re-run provisioner (10 min). Cast mode: nothing on the card
matters. Persistent mode: her real state is server-side; the card holds only the
API credential — revoke the old key and issue a new one when re-provisioning.
**Prevention:** enable Overlay FS after burn-in (doc 02 §6).

### 8. Kasm upgrade broke the kiosk
Pin the container tag (doc 01 §1). Upgrade deliberately: snapshot appdata,
bump the tag, rerun the doc 01 §7 acceptance test from a laptop *before* the
kids find out.

## Useful commands

```bash
# On the Pi
systemctl status kiosk           # unit state
journalctl -u kiosk -b --no-pager# this boot's kiosk logs
systemctl restart kiosk          # bounce the browser without a reboot
curl -k https://HOST:PORT/api/__healthcheck   # is the server reachable/alive?

# On UNRAID
docker stats                     # per-session resource usage
docker logs kasm-workspaces      # Kasm stack logs (container name per your template)
```
