# Integration tests — hardware-in-the-loop

The integration layer is the F1–F11 acceptance matrix in
[`docs/runbooks/troubleshooting.md`](../../docs/runbooks/troubleshooting.md);
it requires a physical Pi, a display, and a live Kasm server, so it is executed
manually and results are recorded in the README V&V table. Unit tests
(`tests/unit/`) cover everything mockable off-hardware.
