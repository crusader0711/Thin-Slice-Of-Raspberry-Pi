# ADR-0003: Anonymous Session Casting as the default entry mechanism

**Status:** Superseded by ADR-0004

**Context:** Zero-touch boot requires a credential-free path into a session.
Kasm Session Casting with anonymous access maps a static URL to an ephemeral,
auto-provisioned session.

**Decision:** Kiosks open the casting URL in incognito; every boot is
factory-fresh; no credentials exist on the client.

**Consequences:** Strongest client security posture and simplest recovery
model, but no persistence of any kind — which ADR-0004 later found unacceptable
for the primary use case ("her computer"). Cast mode is retained as the
stateless option for shared/guest kiosks.
