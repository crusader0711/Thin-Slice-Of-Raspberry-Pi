# ADR-0001: Thin-client architecture with server-side rendering

**Status:** Accepted

**Context:** Kiosks for young children must be zero-touch, unbreakable by the
user, cheap to replicate, and centrally policed. Fat clients (local browser,
local filtering) put policy and state on hardware a child physically controls.

**Decision:** The Raspberry Pi is a dumb glass terminal. All sessions run in
containers on a self-hosted Kasm Workspaces instance (UNRAID/Docker); the Pi
only decodes a KasmVNC stream. All content filtering and state live server-side.

**Consequences:** Any Pi 3B+ suffices; the SD card is disposable; policy cannot
be bypassed from the client. Trade-off: the server is a single point of failure
for every kiosk, and each concurrent session costs ~2 GB RAM / 2 cores on it.
