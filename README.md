# Cyberdeck lab portfolio

Public, scrubbed summary of a portable **RF / networking / SDR lab** built around Rocky Linux and a role-based golden image family called **Rotre**.

> **Documentation only.** No installers, ISOs, VM disks, image files, license material, or export-controlled software packages live in this repository. Those stay on approved local storage and a portable USB kit.

## Architecture

This lab builds a shared radio-sensing stack that runs the same way on ground stations, high-altitude balloon (HAB) payloads, and unmanned aircraft. One golden Rocky Linux lab image is the common base. Role variants of that image ship under the **Rotre** name: a desktop build for operators on the ground, and a headless build for airborne and other constrained platforms.

Nodes talk over a mobile mesh network. On request they stream compact radio products (spectrum summaries and detections, not bulk raw captures by default) toward a hub that can be reached from outside the operating area. Controlled radio software and related licensed content stay on local hardware and never ride on a shareable cloud mirror. The near-term proof of concept focuses on multi-node sensing, geolocation handoff to a hub, and remote reachability for the people who need the picture.

## What this lab is for

Operators need a repeatable way to stand up RF-aware computers for three layers of a field architecture:

1. **Ground stations** — people nearby, desktop workflow, radios attached locally.
2. **High-altitude balloon (HAB) nodes** — headless compute aloft; stream RF data on request; mesh radio as the downlink/backhaul.
3. **UAS nodes** — headless compute between ground and HAB; same golden base, slimmer install; airframe hardware still TBD.

All three share one **Rotre** lab base image (Rocky Linux + open SDR tools + a separately licensed RF analysis stack that is **never** published here). Per-role variants differ mainly by desktop vs headless and size.

## Rotre (lab milestone v0.1.0)

| Role | Shape |
|------|--------|
| ground | Desktop lab image |
| hab | Headless balloon profile |
| uas | Headless UAS profile (slimmed) |

Images are built with an automated VirtualBox pipeline on the lab PC, generalized (machine identity wiped), exported as compressed disk images, hash-checked, then flashed to spare media. Controlled software and licences stay local.

**Public guides (scrubbed):**

- [HOW-TO-Rotre-Flash.md](HOW-TO-Rotre-Flash.md) — flash and first boot
- [HOW-TO-Rotre-From-Scratch.md](HOW-TO-Rotre-From-Scratch.md) — rebuild overview (no controlled paths)
- [TROUBLESHOOT-Rotre.md](TROUBLESHOOT-Rotre.md) — common failures
- [HOW-TO-Tailscale-Lab.md](HOW-TO-Tailscale-Lab.md) — install Tailscale, join lab VPN, SSH/SFTP
- [HOWTO-Rocky-SDR-VM.md](docs/cyberdeck/HOWTO-Rocky-SDR-VM.md) — Rocky + VirtualBox SDR guest basics
- [NETWORK-SOP.md](NETWORK-SOP.md) — lab networking (scrubbed)
- [CMD-REFERENCE.md](CMD-REFERENCE.md) — command cipher: every command in these guides, grouped by task, with cautions
- [LAB-TODO.md](LAB-TODO.md) / [TASK-REGISTRY.md](TASK-REGISTRY.md) — open work
- [CHANGELOG.md](CHANGELOG.md) / [PATCHNOTES.md](PATCHNOTES.md) / [KNOWN-ISSUES.md](docs/cyberdeck/KNOWN-ISSUES.md)

Private repo (team): full pipeline commands, mesh addressing, and keeper paths.

## Rebuild (high level)

1. Install Rocky from local ISO with the lab kickstart (hybrid UEFI/BIOS disk).
2. Apply base post-install (packages, open SDR RPMs, RF stack from a **local** keeper tarball with **no** licence baked in, Tailscale installed but not joined).
3. Apply a role profile (ground / hab / uas).
4. Run generalize (clears machine-id, SSH host keys, network state, Tailscale state; refuses if licence/key material remains).
5. Export compressed image + SHA256; flash with Etcher/Rufus; first boot grows the disk and remakes host keys.

Never publish image files or the RF-stack tarball to git or public cloud.

## Filing rules (summary)

- Installers, ISOs, VM disks, RF captures, golden images, controlled software: **local (+ USB kit) only**.
- Licence keys and credentials: offline secrets vault only — never git.
- Docs use project-relative paths; no personal names or host account paths.

## Status (2026-10-06)

Ground / HAB / UAS lab image variants are built, hash-verified, and boot-tested. Flashing and rebuild HOW-TOs are published here in scrubbed form. Tag **v0.1.0** marks this Rotre lab milestone.

## Public scrub gate
Publishes must pass [`scripts/public-scrub-check.sh`](scripts/public-scrub-check.sh) (see [docs/PUBLIC-SCRUB-GATE.md](docs/PUBLIC-SCRUB-GATE.md)). Enable `scripts/ci/public-scrub-gate.yml.example` as a GitHub Action when `workflow` scope is available.
