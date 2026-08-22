# 01 — Server Setup: Kasm Workspaces on UNRAID

**Objective:** a running Kasm Workspaces 1.18.x instance on UNRAID with a Casting
URL that launches a filtered, anonymous browser session with zero prompts.

**Time:** ~30 min (excluding image pulls).

---

## 1. Install Kasm Workspaces (UNRAID Community Apps)

Kasm is normally a multi-container stack (db, redis, api, manager, agent, proxy).
On UNRAID, the practical deployment is the **single-container** `kasmweb/workspaces`
image from Community Apps, which runs the full stack inside one container
(Docker-in-Docker style).

1. **Apps** tab → search **"Kasm Workspaces"** → Install.
2. Template fields that matter:

| Field | Value | Notes |
|---|---|---|
| Repository | `kasmweb/workspaces:1.18.0` | Pin the tag. Avoid `:latest` for reproducibility; upgrade deliberately. |
| Web UI port | `8443` (host) → `443` (container) | Any free host port. All URLs below use `https://<UNRAID_IP>:<PORT>`. |
| `/opt` data path | `/mnt/user/appdata/kasm/opt` | Kasm's entire state (DB, config, certs) |
| `/profiles` path | `/mnt/user/appdata/kasm/profiles` | Only used if you later enable persistent profiles |
| Privileged / DinD | As required by the template | The container spawns session containers internally |
| Extra env (optional) | `KASM_PORT=443` | Per template docs |

3. Start the container. First boot takes several minutes (it initializes an
   internal database and generates credentials).
4. Get the auto-generated admin password from the container log
   (**Docker tab → Kasm → Logs**, look for `admin@kasm.local` credentials), or per
   the template's documentation.
5. Log in at `https://<UNRAID_IP>:<PORT>` as `admin@kasm.local`. **Change the
   password immediately** and store it in your password manager.

> **Resource planning:** each live session ≈ 1–2 GB RAM and 1–2 cores. Budget
> `(number of kiosks + 1) × 2 GB` of headroom on the UNRAID box. Check with
> `docker stats` while a test session runs.

## 2. Choose and configure the Workspace (the kids' browser)

1. **Workspaces → Registry** (or **Workspaces → Add Workspace**): install a
   browser image, e.g. `kasmweb/chrome` or `kasmweb/firefox` matching your Kasm
   version tag.
2. Edit the Workspace:
   - **Cores / Memory:** 2 cores, 1536–2048 MB — plenty for a kid's browsing.
   - **Persistent Profile:** *disabled*.
   - **Docker Network:** default.
3. (Optional) Set the session's home page via the workspace's *Launch Config*
   JSON, e.g. `{"url": "https://www.pbskids.org"}` so the streamed browser opens
   somewhere friendly.

## 3. Web filtering (server-side, unbypassable from the kiosk)

1. **Admin → Web Filter Policies → Add Policy**:
   - Enable **SafeSearch enforcement**.
   - Enable category filtering; block at minimum: adult, gambling, weapons,
     violence, drugs, social media (your call), proxies/anonymizers.
   - Optionally use **whitelist mode**: deny-all + an allow-list of ~10–20 kid
     sites. For young children this is the strongest and least surprising policy.
2. Assign the policy to the **Group** that the anonymous/casting users land in
   (see §4), or directly on the Workspace image.

Filtering happens inside the session container on the server. Nothing on the Pi
can disable it.

## 4. Session Casting (the auto-login mechanism)

Casting is a Kasm feature that maps a static URL to "provision a session of
workspace X." With anonymous access enabled, visiting the URL requires **no
credentials at all** — Kasm creates an ephemeral user, starts the container, and
attaches the viewer.

**Admin → Access Management → Casting → Add Casting Config:**

| Field | Value | Rationale |
|---|---|---|
| Casting Config Key | `<CAST_KEY>` | URL slug → `https://<UNRAID_IP>:<PORT>/#/cast/<CAST_KEY>` |
| Workspace / Image | the browser workspace from §2 | |
| **Allow Anonymous Access** | ✅ | The entire zero-touch property hangs on this |
| Limit Total Sessions | kiosk count + 1 | Bounds a reload-loop's blast radius on server RAM |
| Limit Sessions per IP | 2 | Same, per device |
| **Allowed IPs / Referrers** | your kiosk subnet, e.g. `<KIOSK_SUBNET>/24` | The URL is otherwise open to anyone on the LAN |
| Require Recaptcha | ❌ | Would break autonomy |

If your Kasm version places anonymous access behind a global setting, also check
**Admin → Settings → Auth** for the anonymous-user toggle and confirm the group
that anonymous users join — that's the group your §3 filter policy must cover.

## 5. Session hygiene settings

On the Workspace / Group settings:

- **Idle timeout / disconnect:** 20–30 min. Abandoned sessions self-destruct and
  free server RAM.
- **Session time limit (optional):** a hard cap if you want built-in screen-time
  enforcement. When it expires the session ends; the kiosk shows Kasm's
  session-ended page until the next reload/reboot mints a fresh one.

## 6. TLS decision (read this — it's the #1 failure point)

Kasm generates a **self-signed certificate**. An unattended Chromium will halt at
the certificate interstitial and the kiosk is dead on arrival. Pick one:

**Option A — proper certificate (recommended, do eventually):**
1. Give the server an internal FQDN (e.g. `<SERVER_FQDN>`).
2. Issue a real cert via Let's Encrypt **DNS-01** (no inbound exposure needed) or
   your internal CA.
3. Install cert+key per Kasm docs (replace the certs under Kasm's `/opt` data
   path, or terminate TLS at a reverse proxy in front of Kasm).
4. If using an internal CA: copy the CA root to each Pi at
   `/usr/local/share/ca-certificates/homelab-ca.crt` and run
   `sudo update-ca-certificates` (the provisioner has a hook for this).

**Option B — ship today on a trusted LAN:**
run the provisioner with `IGNORE_TLS=1`, which adds
`--ignore-certificate-errors` to Chromium. Blunt (ignores *all* cert errors),
but acceptable when the kiosk VLAN can only reach the Kasm host anyway. Replace
with Option A when convenient.

## 7. Acceptance test (do not skip)

From a laptop, in a **private/incognito window**, open:

```
https://<UNRAID_IP>:<PORT>/#/cast/<CAST_KEY>
```

Pass criteria: a live, filtered browser session appears with **zero clicks and
zero prompts** (Option A) or only the cert warning (Option B — which the Pi flag
suppresses). Test the filter: search something blocked; confirm the block page.

The Pi can only ever reproduce what this URL does. Fix everything at this layer
first.

## 8. Persistent mode: per-child kiosks (recommended for "her computer")

Anonymous casting gives a clean slate every boot. If instead each kiosk should
be *one child's computer* — bookmarks, saved files, and settings surviving
reboots and session stops — configure persistent mode. The kiosk then obtains a
no-password login for its bound user at every boot via the Kasm Developer API,
and all state lives server-side in that user's persistent profile.

### 8.1 Create the child's user and group

1. **Access Management → Groups → Add Group**: e.g. `Kids`.
   - Attach the §3 **Web Filter Policy** to this group.
   - Group settings: enable the **auto-launch default workspace on login**
     setting (named *Auto Login Kasm* / similar in the group settings list) so
     login lands directly in her session, never on a dashboard.
2. **Access Management → Users → Add User**: e.g. `<CHILD_USERNAME>@kiosk.local`,
   strong random password (she will never type it — the API logs her in).
   Add her to `Kids`.
3. Open the user's detail page and record the **User ID (UUID)** — the
   provisioner needs it as `KASM_USER_ID`.

### 8.2 Enable the persistent profile on the workspace

Edit the browser Workspace (§2):

- **Persistent Profile Path:** `/profiles/{username}` — the `{username}` token
  gives each child an isolated profile directory under the `/profiles` volume
  you mapped in §1.
- Confirm the UNRAID path behind `/profiles` has space and is on a share you
  back up: this directory *is* her computer now.

What persists: bookmarks, browser settings, downloads kept in the profile,
logins to kid sites. What does not: exact open tabs, *if* the session container
itself was destroyed (see 8.4).

### 8.3 Create a least-privilege API key

**Admin → Settings → Developers → Add API Key**:

- Grant **only** the `Users Auth Session` permission — that is all
  `get_login` requires. Do not grant admin scopes; this key lives on the kiosk.
- Record the key and secret for the provisioner (`KASM_API_KEY`,
  `KASM_API_SECRET`). Prefer one key per kiosk so a compromised device can be
  revoked individually.

### 8.4 Session continuity semantics (set expectations)

Two layers of "coming back to her stuff":

| Event | What she sees on return |
|---|---|
| Disconnect / kiosk reboot while the session container still exists | **Exact same session** — open tabs and all. Kasm reattaches her to the running container. |
| Session container destroyed (idle limit hit, server reboot, nightly cleanup) | **Fresh session, same identity** — bookmarks/settings/files restored from the persistent profile; open tabs are not. |

Tune the boundary in Workspace/Group settings: raise the **idle destroy /
keepalive expiration** timers to widen the "exact same session" window.

### 8.5 Acceptance test (persistent mode)

From a laptop: call `get_login` for her user id (curl, same payload the kiosk
uses — see `src/pi/get-login-url.sh`), open the returned URL in a private window.
Pass criteria: lands *directly in her filtered session* with zero prompts.
Create a bookmark, destroy the session from the admin panel, repeat the call:
the bookmark must be back.
