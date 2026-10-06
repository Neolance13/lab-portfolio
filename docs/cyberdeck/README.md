# Cyberdeck lab (public summary)

Sanitized, public summary of the Cyberdeck lab: a portable toolkit workspace for RF, networking, development, 3D printing, and design, with a Rocky Linux VirtualBox guest used for SDR work.

> This folder contains **documentation only**. No installers, ISOs, VM images, license material, or controlled/export-restricted software details. Those stay on approved local or private storage.

## Layout (project-relative)

| Path | Contents |
|------|----------|
| `Installers/` | Reinstall keepers by category (`Net`, `RF`, `Dev`, `Print3D`, `Design`, `Apps`) - local only |
| `Images/ISOs` | Distro ISOs - local only |
| `Images/Xfer` | Transfer ISOs used to move packages into guests - local only |
| `VMs/` | VirtualBox machine folders - local only |
| `VMs/exports/` | Active OVA / snapshot working copies - local only |
| `Archive/YYYY-MM-DD/` | Retired docs, installers, snapshots, OVAs (never delete; dated buckets) - local only |
| `RF/` | Captures - local only |
| `Projects/` | Active work |
| `Docs/` | Patch notes, known issues, lab TODO |

## Lab status (2026-10-06)

| Item | Status |
|------|--------|
| Hypervisor | VirtualBox 7.2.20 |
| Guest | Rocky Linux 10.2, 8 GB RAM, 4 vCPU, 60 GB disk, NAT; VM folder on local `VMs/` with a second local copy; offline pre-change snapshot taken |
| RF application | Licensed RF analysis package installed in guest from a local transfer ISO (details kept private) |
| USB | xHCI (USB 3.0) controller; one USB filter per SDR vendor (RTL-SDR `0bda:2838`) |
| Guest device access | udev rule for USB / serial, RTL-SDR DVB driver blacklisted, operator in `dialout` |
| Archive / backups | Dated `Archive/YYYY-MM-DD/` buckets; active exports under `VMs/exports/`; controlled media has a second local copy on a separate local disk (never cloud) |
| Remote access | SSH key-only (localhost; VM joined the lab tailnet); guest additions installed; pre-release hardening tracked |
| Lab network and images | Lab mesh emulator and hub VMs built and tested; ground / HAB / UAS lab image variants built and boot-tested (flashing docs private). Controlled software stays on approved local storage only |
| Next | Build and test remaining node VMs; pre-release hardening |
| Roadmap | One base image with desktop and headless variants for fixed, airborne and unmanned platforms |

## Docs

- [PATCHNOTES.md](PATCHNOTES.md) - dated host / guest changes
- [KNOWN-ISSUES.md](KNOWN-ISSUES.md) - issues and workarounds
- [LAB-TODO.md](LAB-TODO.md) - open tasks and roadmap
- [HOWTO-Rocky-SDR-VM.md](HOWTO-Rocky-SDR-VM.md) - Rocky + VirtualBox SDR guest setup
- [NETWORK-SOP.md](NETWORK-SOP.md) - lab network SOP v1, scrubbed public copy (lab mesh emulator and hub VMs built and tested; node VMs not yet built): flat 10.X.0.0/16 mesh, netem mesh emulator, hub services, node config on the EFI partition. Scripts and configs are not published
- [FILING-SOP.md](FILING-SOP.md) - sanitized filing and archive rules (v3.6)
- [BOT-SOP.md](BOT-SOP.md) - bot roles, messaging, approvals, and handoff rules
- [TASK-REGISTRY.md](TASK-REGISTRY.md) - task owner map (one owner per task)
- [CHANGELOG.md](CHANGELOG.md) - public running log (sanitized)
- [Archive-README.md](Archive-README.md) - how dated Archive buckets work

An RF / host reference glossary and research briefs are kept in private storage only and are not published here.

## Filing rules (summary)

- Installers, ISOs, VM disks, RF captures, and controlled software: local disk only - never git or cloud sync.
- OneDrive is retired. Four approved locations: local (plus second local copy), removable USB kit (physical only), GitHub (docs + scripts), Drive (docs only).
- Controlled / export-restricted installers and VM images: second **local** copy on a separate local disk (assigned 2026-10-05); never cloud.
- Superseded docs, old installers, retired snapshots/OVAs -> `Archive/YYYY-MM-DD/...` (never delete; log moves).
- Active OVA/snapshot working copies -> `VMs/exports/`; retired copies -> Archive.
- License keys and credentials: local secrets file only (gitignored; never git, Drive, or cloud).
- Docs use project-relative paths; no hostnames or personal paths.
- Never touch application installs, games, or OS/system files for filing.
