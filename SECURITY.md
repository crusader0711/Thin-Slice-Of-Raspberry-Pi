# Security Policy

## Supported versions

| Version | Supported |
|---|---|
| 2.x (latest release) | ✅ |
| < 2.0 | ❌ |

## Reporting a vulnerability

Coordinated disclosure, 90-day window. Report privately via GitHub Security
Advisories on this repository (preferred) or a GitHub issue marked only
"security — contact requested" with no technical detail; a private channel
will be provided.

## Scope notes for reporters

The interesting attack surface is: the on-kiosk API credential
(`Users Auth Session` scope), the unauthenticated casting URL (IP-restricted
by config), and the `IGNORE_TLS` stopgap path. Findings that assume physical
possession of the SD card should reference risk R7 in the README register.
