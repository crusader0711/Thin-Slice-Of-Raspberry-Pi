# Runbook: re-provision a kiosk from scratch

**When:** SD corruption, mode change, credential rotation, or new kiosk.
**Time:** ~30 min. **Data risk:** none — state is server-side.

1. (Persistent mode, if the old card may be compromised) Admin → Settings →
   Developers: revoke the kiosk's API key; mint a replacement.
2. Flash Raspberry Pi OS Lite (64-bit) with SSH enabled (docs/02 §2).
3. Clone the repo on the Pi; run the matching example from `examples/`
   with real values.
4. Verify F1–F3 minimum (`docs/runbooks/troubleshooting.md`); F9–F10 for
   persistent mode.
5. Update the fleet notes (which key belongs to which kiosk).
