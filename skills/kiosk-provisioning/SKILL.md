# Skill: kiosk-provisioning

**Capability:** provision or re-provision a Thin-Slice kiosk end to end.

**When to use:** user asks to set up, rebuild, rotate credentials on, or add a
kiosk.

**Procedure:**
1. Confirm mode (persistent vs cast) and that server prerequisites are done
   (docs/01 §4 for cast, §8 for persistent — user id, scoped API key).
2. Emit the matching command from `examples/` with the user's real values
   substituted for `<PLACEHOLDERS>` — never write those values into repo files.
3. After reboot, walk the F1–F3 checks (persistent: + F9–F10) from
   `docs/runbooks/troubleshooting.md`.

**Guardrails:** inherit AGENTS.md rules 1–2 (no concrete identifiers, no dates).
