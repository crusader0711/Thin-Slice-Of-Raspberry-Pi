# BUILD — Step-by-Step

A linear, soup-to-nuts build of one persistent-mode kiosk from parts on the
bench to a child using it. Every phase ends with a **checkpoint** — do not
advance past a failed checkpoint; each phase only reproduces what the previous
one proved. Reference docs go deeper: [docs/01-server-setup.md](docs/01-server-setup.md),
[docs/02-pi-setup.md](docs/02-pi-setup.md),
[docs/runbooks/troubleshooting.md](docs/runbooks/troubleshooting.md).

**Total time:** ~2 hours active (excluding image pulls and the 7-day burn-in).

---

## Phase 0 — Parts & prerequisites (~10 min)

**Gather:**

- [ ] Raspberry Pi 3B+ / 4 / 5 + official PSU + case
- [ ] microSD ≥ 16 GB (A1/A2, endurance-rated preferred)
- [ ] HDMI display, USB keyboard + mouse
- [ ] Ethernet run to the kiosk location (strongly preferred over Wi-Fi)
- [ ] UNRAID server with headroom: **2 GB RAM + 2 cores per concurrent
      session**, plus space on a backed-up share for `/profiles`
- [ ] A workstation with Raspberry Pi Imager and SSH

**Decide now** (details: README → Design decisions):

| Decision | This guide builds | Alternative |
|---|---|---|
| Mode | **Persistent** (her computer, state survives reboots) | Cast (stateless shared kiosk) — substitute Phase 2b/4b |
| TLS | `IGNORE_TLS=1` stopgap on a locked-down LAN | Proper cert (docs/01 §6 Option A) — do it eventually |

**Checkpoint 0:** parts on the bench; server share picked for `/profiles`.

---

## Phase 1 — Kasm Workspaces on UNRAID (~30 min, mostly pulls)

1. UNRAID **Apps** tab → search *Kasm Workspaces* → install the
   `kasmweb/workspaces` template.
2. Set template fields — **pin the version tag** (e.g. `:1.18.0`, never
   `:latest`), map the web UI port (host `<PORT>` → container 443), and map:
   - `/opt` → `/mnt/user/appdata/kasm/opt`
   - `/profiles` → a **backed-up** share path (this becomes her computer)
3. Start the container; first boot initializes the internal DB (several
   minutes). Pull the generated admin credentials from the container log.
4. Log in at `https://<UNRAID_IP>:<PORT>` as `admin@kasm.local` → change the
   password immediately.
5. **Workspaces → Registry**: install a browser workspace
   (`kasmweb/chrome`, tag matching your Kasm version). Edit it: 2 cores,
   1536–2048 MB, and set **Persistent Profile Path** = `/profiles/{username}`.
6. **Admin → Web Filter Policies**: create the kids' policy — SafeSearch
   enforced + category blocking (or whitelist mode for young children).

**Checkpoint 1:** from your workstation, launch the workspace manually from
the admin account — a filtered browser session streams in your browser, and a
blocked search shows the block page. *(docs/01 §1–§3 for detail.)*

---

## Phase 2 — Her identity on the server (~15 min)

1. **Access Management → Groups → Add Group** `Kids`:
   - attach the Phase-1 Web Filter Policy;
   - enable the **auto-launch default workspace on login** group setting (so
     login lands in her session, never a dashboard);
   - set idle/keepalive timers — this tunes how long "come back to the exact
     same tabs" lasts (docs/01 §8.4).
2. **Access Management → Users → Add User** `<CHILD_USERNAME>@kiosk.local`,
   strong random password (she never types it), member of `Kids`.
3. Open her user page → record the **User ID (UUID)** → `<KASM_USER_UUID>`.
4. **Admin → Settings → Developers → Add API Key** with **only** the
   `Users Auth Session` permission. Record `<API_KEY>` / `<API_SECRET>`.
   One key per kiosk — individually revocable.

**Checkpoint 2 (the acceptance test that gates everything):** from your
workstation, simulate the kiosk's exact call:

```bash
curl -ks -X POST "https://<UNRAID_IP>:<PORT>/api/public/get_login" \
  -H 'Content-Type: application/json' \
  -d '{"api_key":"<API_KEY>","api_key_secret":"<API_SECRET>","target_user":{"user_id":"<KASM_USER_UUID>"}}'
```

Open the returned `url` in a private browser window. **Pass:** you land
directly in her filtered session, zero prompts. Then: create a bookmark →
destroy her session in the admin panel → repeat the call → **the bookmark is
back.** If any of that fails, fix it here — the Pi only replays this flow.

> **Phase 2b (cast mode instead):** skip the above; create the anonymous
> Casting config per docs/01 §4 and verify the cast URL the same way.

---

## Phase 3 — Flash the Pi (~10 min)

1. Raspberry Pi Imager → **Raspberry Pi OS Lite (64-bit)** (Bookworm).
2. Customization (gear icon): hostname `kiosk-01`, **enable SSH** (key auth),
   locale/keyboard. Wi-Fi credentials only if Ethernet is impossible.
3. Flash, insert, connect Ethernet + display, power on.
4. Find its DHCP lease; SSH in.

**Checkpoint 3:** `ssh <admin>@kiosk-01` works; `ping <UNRAID_IP>` succeeds
from the Pi (routing/VLAN path is good).

---

## Phase 4 — Provision (~15 min)

On the Pi:

```bash
sudo apt update && sudo apt install -y git
git clone https://github.com/Crusader0711/Thin-Slice-Of-Raspberry-Pi.git
cd Thin-Slice-Of-Raspberry-Pi

sudo KASM_HOST="<UNRAID_IP>:<PORT>" \
     KASM_USER_ID="<KASM_USER_UUID>" \
     KASM_API_KEY="<API_KEY>" \
     KASM_API_SECRET="<API_SECRET>" \
     IGNORE_TLS=1 \
     ./src/pi/provision.sh
```

The provisioner is idempotent (re-run any time with new values). It installs
`cage`/Chromium/`jq`, creates the unprivileged `kiosk` user, writes
`/etc/kiosk.conf` (0600), installs the health-gated systemd unit, kills screen
blanking, schedules the 04:00 self-heal reboot, and reboots into the kiosk.
*(What each step does and why: docs/02 §4.)*

> **Phase 4b (cast mode):** same command with `CAST_KEY="<CAST_KEY>"` instead
> of the three persistent-mode variables. See `examples/`.

**Checkpoint 4:** after the reboot, the display goes: blank → (up to ~60 s) →
**her session, fullscreen, no interaction.** If it stalls, diagnose with the
flowchart in docs/runbooks/troubleshooting.md — the two usual suspects are the
TLS interstitial (missing `IGNORE_TLS=1`) and a mistyped `KASM_HOST`.

---

## Phase 5 — Verification (~20 min, do not skip)

Run the acceptance matrix (full table: docs/runbooks/troubleshooting.md).
Minimum gate for handover:

| # | Do | Pass looks like |
|---|---|---|
| F1 | Cold boot, stopwatch | Session live ≤ 60 s, zero touches |
| F2 | Boot with Ethernet unplugged; plug in after a minute | Recovers unaided |
| F3 | `sudo pkill chromium` over SSH | Browser back in ~5 s |
| F9 | Reboot mid-use, return promptly | Same session, same open tabs |
| F10 | Destroy her session from admin, reboot kiosk | Fresh session, bookmarks intact |
| F11 | Temporarily revoke the API key, reboot | Kasm login page (degraded), not a dead screen — then re-enable the key |

Record results in the README V&V table (that's the honest-Δ discipline).

---

## Phase 6 — Hardening (after ~7 fault-free days)

- [ ] Firewall: kiosk VLAN → Kasm host:`<PORT>` **allow**; all other kiosk
      egress **deny** (re-open apt temporarily for updates).
- [ ] Overlay (read-only) filesystem: `raspi-config` → Performance → Overlay FS
      — makes the SD immune to power-yank corruption. Do this **last**; config
      changes require disabling it first.
- [ ] Replace `IGNORE_TLS=1` with a proper certificate (docs/01 §6 Option A),
      re-run the provisioner without the flag, re-pass F1.
- [ ] Confirm the `/profiles` share is in your backup job — it is her computer.

---

## Phase 7 — Handover (~5 min)

Print [docs/03-user-guide.md](docs/03-user-guide.md), tape it near the kiosk,
and demonstrate the entire operating procedure: **power on → wait → use →
power off.** The one fix she or any adult ever needs: turn it off and back on
— everything important lives on the server.

**Additional kiosks:** repeat Phases 2–5 per child (new user, new scoped API
key, new SD card, hostname `kiosk-02`…), and follow
[docs/runbooks/reprovision-kiosk.md](docs/runbooks/reprovision-kiosk.md) for
rebuilds and credential rotation.
