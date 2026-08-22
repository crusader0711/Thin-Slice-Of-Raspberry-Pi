# ADR-0002: cage single-application Wayland compositor, not a desktop

**Status:** Accepted

**Context:** Desktop-autostart kiosks (v1.x) leak escape surface: taskbars,
notification popups, Alt-Tab, and VT switching all sit underneath the browser.

**Decision:** Run `cage` on tty1 via a health-gated systemd unit
(`Restart=always`); the browser is the only application the display server can
show. `getty@tty1` is disabled.

**Consequences:** Kiosk-escape hardening collapses to near-zero configuration;
crash recovery and autostart come from one systemd mechanism. Trade-off:
no local fallback UI exists — diagnostics are SSH-only by design.
