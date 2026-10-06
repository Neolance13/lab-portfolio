# Cyberdeck Changelog (public summary)

Sanitized running log. No secrets, license material, controlled product names, or host identifiers.

## [Unreleased]
### Lab (latest)
- 2026-10-06: public command reference added ([CMD-REFERENCE.md](CMD-REFERENCE.md)): every command in the public guides grouped by task, with plain-words meaning and cautions; team bot SOP updated (new teammate for side projects outside this lab; research shared across all teammates)
- 2026-10-06: lab builds of all three role variants (ground desktop, airborne headless, unmanned headless) built and boot-tested, published under the **Rotre** name as v0.1.0 (lab builds, not releases); test VMs per role on the lab mesh
- 2026-10-06: public guides added: [Rotre flash](HOW-TO-Rotre-Flash.md), [Rotre build from scratch](HOW-TO-Rotre-From-Scratch.md), [Rotre troubleshooting](TROUBLESHOOT-Rotre.md), [lab remote access](HOW-TO-Tailscale-Lab.md)
- 2026-10-05: first ground-station lab image built and boot-tested (UEFI/BIOS)
- 2026-10-05: lab mesh emulator and hub VMs built; network SOP updated with build fixes and a bursty-loss (Gilbert-Elliott) contested profile
- 2026-10-05: separate build VM with offline snapshot stages
- 2026-10-05: SDR++ built from source and verified with RTL-SDR
- 2026-10-05: VM joined the lab tailnet; SSH key-only
- 2026-10-05: hardening note - guest firewall zone to be restricted before any release build (tracked)
- VM folder moved off cloud sync to local `VMs/`; second local copy on a separate disk (size-matched)
- Earlier live snapshot failed on the cloud-sync path; offline pre-change snapshot taken instead. Lesson: snapshots only when powered off
- Remote access: localhost-only SSH with key auth configured; guest additions installed; pre-release hardening tracked
- Temporary lab-only convenience settings; hardening checklist tracked before any release build
- RTL-SDR passthrough verified
- 2026-10-05: VirtualBox Extension Pack kept (personal/non-commercial lab use)
- 2026-10-05: Tailscale lab tailnet created (free plan)
- 2026-10-05: SDR USB filters per device family planned; old transfer screenshot archived (not deleted)

### Docs
- 2026-10-06: public scrub gate added (`scripts/public-scrub-check.sh`, pre-push hook template, GitHub Action); history rewritten to drop leaked private details from earlier commits (tree matches prior scrubbed tip)
- 2026-10-06: public copies re-scrubbed - the lab logs (changelog, patch notes, TODO, task registry) and the new guides had picked up private host, account, platform and image details; public summaries restored
- Lab network SOP v1: flat 10.X.0.0/16 mesh, emu-01 netem emulator, hub-01 MQTT/DNS/NTP, node.conf on the EFI partition.
- 2026-10-05: roadmap restructured - one base image with desktop and headless variants for fixed, airborne and unmanned platforms; image operator account defined; hardening items tracked
- 2026-10-05: roadmap item renamed to "headless node image for embedded units"
- 2026-10-05: docs sync - SDR tool, tailnet join and hardening note recorded; stale items refreshed (RTL-SDR verify done, USB filter status)
- 2026-10-05: docs sync - stale remote-access status corrected; Extension Pack decision and lab tailnet recorded
- OneDrive retired; four approved locations (local + second copy / removable USB kit / GitHub docs+scripts / Drive docs only) added to BOT-SOP and Filing SOP v3.6
- Two more research briefs filed privately (kept in private cyberdeck / Drive); omitted from public lab-portfolio
- Planned vendor inquiry cancelled; lab work continues on free / low-cost SDR tools
- RF / host reference glossary filed privately (kept in private cyberdeck / Drive); omitted from public lab-portfolio
- Cyber Team naming in BOT-SOP; Mail Bot handles team correspondence / in-person fallback only as last resort (Ghost Lead notify); Inno→Mail→Ghost outside-contact flow (§7); operator is a limited resource (§8)
- Inno Bot research brief filed privately (kept in private cyberdeck / Drive); omitted from public lab-portfolio
- Contact-name / judgment-escalation scrub: Mail Bot uses judgment escalation rule (no named contacts; no private contact-list pointer)


### Docs
- Manager rename: Ghost Lead (was Grok Bot); Inno Bot added (recommends only); File Bot sole docs writer; BOT-SOP chain-of-command + USERPASS summary; TASK-REGISTRY refresh

### Lab

- Rocky Linux 10.2 VirtualBox guest for SDR work (8 GB RAM, 4 vCPU, 60 GB, NAT)
- Licensed RF analysis package installed in guest from a local transfer ISO (details private)
- Guest device access: udev for USB/serial, RTL-SDR DVB blacklist, operator in `dialout`; host USB xHCI + per-vendor SDR filter
- Secondary RF analysis package staged for later install (vendor freeware; matching hardware required; not installed yet)
- Remote-access prep: pre-change live snapshot hung, then failed (superseded by the offline snapshot above); SDR attach in guest pending
- VM folder relocation to local `VMs/`: done (see Lab (latest))

### Docs

- Operator Docs/ set: PATCHNOTES, KNOWN-ISSUES, LAB-TODO
- Filing SOP bumped to **v3.5** (credentials -> local secrets file only; second local copy assigned)
- New [BOT-SOP.md](docs/cyberdeck/BOT-SOP.md) (bot roles, messaging, approvals; File Bot sole writer; judgment-escalation mail replies go to Ghost Lead with a draft for approval, never auto-sent; chain-of-command)
- New [TASK-REGISTRY.md](TASK-REGISTRY.md) (one owner per task; Ghost Lead, Inno Bot recommends / Cyber implements)
- **Archive and Backups baseline:** dated `Archive/YYYY-MM-DD/{docs,installers,snapshots,ova}/` placeholders; `VMs/exports/` for active exports; controlled media second-local-copy policy (never cloud); weekly backup check noted

### Known blockers

- License entitlement required for RF package activation (key in local secrets file only)

## 2026-10-05 - Second local copy, secrets handling, bot SOP

- Second local copy of controlled installers and OS/transfer images created on a separate local disk (hash-verified); VM disk deferred until power-off
- Credentials moved to a local-only, gitignored secrets file; docs reference it instead of holding values
- Added BOT-SOP and TASK-REGISTRY; Filing SOP v3.4 -> v3.5

## 2026-10-05 - Archive and Backups baseline

- Created dated Archive bucket tree (empty placeholders; no mass moves)
- Added Archive README; created `VMs/exports/`
- Filing SOP v3.3 -> v3.4 (Archive and Backups section)

## 2026-10-05 - Lab progress

- RF analysis package installed in Rocky guest from a fixed transfer ISO
- Guest udev / blacklist / groups / firewall zone applied
- Host Extension Pack and USB filter configured
- Docs/ folder created; Filing SOP v3.3

## 2026-10-05 - Baseline

- Initial Cyberdeck layout; Filing SOP; README; Rocky SDR how-to; local media staging
