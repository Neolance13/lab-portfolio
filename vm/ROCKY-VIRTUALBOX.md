# Rocky Linux on VirtualBox (checklist)

Public checklist only — no media or secrets.

## Prerequisites

- VirtualBox (verified working: 7.x)
- Rocky Linux DVD ISO stored locally (not in this repo)
- Optional: unattended install or kickstart for repeatability

## Suggested VM shape (starting point)

Adjust to host capacity:

- Name: `Rocky10-SDR` (or reuse an existing `Rocky` VM)
- CPUs / RAM: match host (lab host previously used a high-CPU saved VM; prefer modest defaults for portability)
- Disk: ≥ 40 GB dynamically allocated VDI for app installs
- Network: NAT for first boot; host-only/bridged later as needed

## Build steps

1. Create VM and attach Rocky DVD ISO
2. Install Rocky; enable SSH if you will automate later
3. Snapshot `clean-os` before application installs
4. Install lab applications from *local* installer media
5. Smoke-test
6. Snapshot `apps-ok`
7. Export **OVA** for multi-device VirtualBox import (`File → Export Appliance` or `VBoxManage export`)

## Multi-device rollout

- Prefer OVA for VirtualBox-to-VirtualBox
- Keep OVAs on fast local or approved shared storage — not in git
- Document hostname, users, and first-boot steps in `docs/` (no passwords in git)
