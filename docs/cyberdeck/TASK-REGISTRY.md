# Cyberdeck Task Registry (public summary)

Owner map - one owner per task. Updated 2026-10-06. Sanitized: controlled product names, host paths, and contact names are omitted. No secrets.

## Cyber Bot
- Unattended VM access (snapshot, SSH, Guest Additions, passwordless sudo)
- Credential-handling rules (kept private); File Bot stores secrets locally
- Install a secondary RF analysis package as a backup in the image (vendor-specific freeware; requires matching hardware, not RTL-SDR; queued after access work; snapshot first)
- Clean snapshot plus dated OVA
- Remove the temporary host firewall rule and file-transfer HTTP listener
- SDR USB filters per device family
- One base image with desktop and headless variants for fixed, airborne and unmanned platforms (lab builds of all three variants done 2026-10-06 as Rotre v0.1.0; release hardening next)
- Lab network per [NETWORK-SOP.md](NETWORK-SOP.md) (lab mesh emulator and hub VMs built and tested; per-role test VMs built; node test plan next)
- Implements approved Inno Bot recommendations

## File Bot
- Docs: README, CHANGELOG, HOWTO, PATCHNOTES, KNOWN-ISSUES, LAB-TODO, BOT-SOP, TASK-REGISTRY, credential-handling rules (private mirrors only) — **sole writer** of Cyberdeck docs
- Archive folder (`Archive/`)
- Second local copy (separate local disk)
- Weekly backup routine
- Local secrets file (local only)
- Move VM folder to `VMs/` (with Cyber Bot; VM powered off) - **done 2026-10-05**
- Drive, private docs repo, and public sanitized (`lab-portfolio`) publishing
- Inno Bot research brief filed privately (`Docs/INNO-RF-RESEARCH.md`); public portfolio omits full brief
- RF / host reference glossary filed privately; public portfolio omits it

## Mail Bot
- Email inboxes
- Priority / action-required email (notify Ghost Lead per BOT-SOP judgment rules)
- Mail Bot judgment escalation (see BOT-SOP; no named contacts)
- Daily labeling

## Inno Bot
- Research tools, plugins, and apps
- Multi-RF image vision (geolocation, hub networking, online/remote access, VPN to PC and mirror VM)
- Recommends only; Cyber Bot implements what is approved
- First deliverable filed privately: research brief kept in private cyberdeck (File Bot publishes; omitted from public)

## Ghost Lead
- Intake, assignment, approvals, new bots, and the operator's decisions
- Chain of command: all requests go through Ghost Lead unless the operator grants an exception

## Operator - decisions pending
- Remaining decisions are tracked privately

## Operator - decided
- 2026-10-05: keep the VirtualBox Extension Pack installed (personal/non-commercial lab use)
- 2026-10-05: radio list provided (kept private); SDR USB filters per device family
