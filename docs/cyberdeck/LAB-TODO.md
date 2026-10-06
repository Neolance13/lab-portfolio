# Cyberdeck Lab TODO (public)

- [ ] Remove temporary host transfer listener and firewall rule
- [x] Power off guest; relocate VM folder to local `VMs/` (+ second local copy)
- [x] Verify RTL-SDR enumerates in guest with DVB driver blacklisted
- [ ] Snapshots: post-install, smoke-ok
- [ ] SDR USB filters per device family
- [ ] Tighten udev / firewalld (restrictive zone) before any release or non-lab deployment
- [ ] Snapshot + OVA export for multi-device reuse

## Roadmap

One base image with desktop and headless variants for fixed, airborne and unmanned platforms. A clean, repeatable install and setup is the foundation.

- [ ] Base image: clean install and setup (validation, per-family SDR filters, release hardening)
- [ ] Lab network per [NETWORK-SOP.md](NETWORK-SOP.md) (lab mesh emulator and hub VMs built and tested; per-role test VMs built 2026-10-06; node test plan still to run): emulator and hub VMs, node config engine in the base image, test plan for desktop and headless nodes
- [x] Desktop variant for fixed sites - lab build v0.1.0 (2026-10-06); release hardening still open
- [x] Headless node image for embedded units (airborne platforms) - lab build v0.1.0 (2026-10-06); flight hardware validation open
- [x] Headless, slimmed variant for unmanned platforms - lab build v0.1.0 (2026-10-06); hardware TBD
- [ ] Release hardening of all three variants before any non-lab use

Done 2026-10-06: lab builds of all three variants (Rotre v0.1.0), public flash / build / troubleshooting guides.

Done 2026-10-05: application install, udev/blacklist/groups/firewalld, xHCI + RTL-SDR filter, docs set.
