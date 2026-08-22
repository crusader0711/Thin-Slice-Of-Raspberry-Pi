# Privacy

This project is self-hosted and makes **no external calls and collects no
telemetry**. Data it touches:

| Data | Where it lives | Retention |
|---|---|---|
| Child's browsing state (bookmarks, files, settings) | Kasm persistent profile on the operator's UNRAID share | Operator-controlled |
| Kasm API credential | `/etc/kiosk.conf` on the kiosk SD card, mode 0600 | Until rotated/revoked |
| Session/browsing logs | Kasm server logging per operator configuration | Operator-controlled |

No data leaves the operator's LAN by design (kiosk VLAN egress is restricted to
the Kasm host). Web filtering happens server-side; filter policy and any
logging visibility are the responsibility of the deploying parent/operator.
