# Cyberdeck Patch Notes (public summary)

Dated operator notes for host and guest changes. Sanitized: no hostnames, account paths, credentials, product keys, or controlled product names. Summary entries live in [CHANGELOG.md](CHANGELOG.md).

---

## 2026-10-06 (PT) - Rotre v0.1.0 lab images and public guides

| Change | Detail |
|--------|--------|
| Images | Lab builds of the ground (desktop), airborne (headless) and unmanned (headless, slim) variants, published under the Rotre name as v0.1.0. Lab builds only; image files stay on approved local storage |
| Guides | Public flash, build-from-scratch, troubleshooting and lab remote-access guides at the repository root |
| Public scrub | Lab logs and guides re-scrubbed after private details slipped into the public copies |

---

## 2026-10-05 (PT, ~16:30) - Lab network SOP v1

| Change | Detail |
|--------|--------|
| Network SOP | Lab network SOP v1 (design only; nothing applied to any VM): flat 10.X.0.0/16 mesh, netem mesh emulator with lab-estimate profiles, hub services (MQTT, DNS/DHCP, NTP), node config on the EFI partition, test plan. Scrubbed public copy: [NETWORK-SOP.md](NETWORK-SOP.md); scripts and configs kept private |

---

## 2026-10-05 (PT) - Roadmap structure

| Change | Detail |
|--------|--------|
| Roadmap | One base image with desktop and headless variants for fixed, airborne and unmanned platforms |
| Accounts | Image operator account defined (details kept private) |

---

## 2026-10-05 (PT) - SDR tool, lab tailnet, hardening note

| Change | Detail |
|--------|--------|
| SDR tool | SDR++ built from source and verified with RTL-SDR |
| Remote access | VM joined the lab tailnet; SSH key-only |
| Hardening | Guest firewall zone to be restricted before any release build (tracked) |

---

## 2026-10-05 (PT) - Remote-access prep, backups, credentials handling

### Host

| Change | Detail |
|--------|--------|
| SSH keypair | ed25519 keypair generated on host for guest access (no passphrase). **Not installed in guest yet.** Path and fingerprint: local credentials file only |
| Live snapshot | Pre-remote-access live snapshot started ~12:57 PT - **hung** (tracked privately) |
| USB | RTL-SDR captured on host but not attached in guest; attach returns busy with previous request |
| Second local copy | Installers and images copied to a separate local disk (hash-verified). VM disk not copied (guest running) |
| Credentials | Local-only secrets file created (gitignored); test-login rules kept private |

---

## 2026-10-05 (PT) - Rocky SDR lab bring-up

### Host

| Change | Detail |
|--------|--------|
| Hypervisor | Oracle VirtualBox 7.2.20 |
| Extension Pack | Oracle VirtualBox Extension Pack 7.2.20 installed |
| VM USB controller | xHCI (USB 3.0) enabled |
| USB filter | RTL-SDR vendor/product filter |
| Temporary firewall rule | Host rule for a media-transfer listener - **pending removal** |
| Temporary HTTP server | Possible file-transfer listener - **pending cleanup** |

**Lesson learned - Extension Pack:** USB 2.0 / 3.0 controllers are built into VirtualBox 7.2; the Extension Pack is **not** required for USB passthrough. Confirm licensing before relying on it in other deployments.

### Guest

| Setting | Value |
|---------|-------|
| OS | Rocky Linux 10.2 |
| Memory / CPU | 8 GB / 4 vCPU |
| Disk | 60 GB |
| Network | NAT |
| State at docs close-out | **Running** - do not move |
| Location | Relocate machine folder to local `VMs/` only when powered off |

#### RF package install

- Licensed RF analysis package installed from a local transfer ISO (details private).
- Run the installer as the **normal desktop user from a GUI terminal**. Running as root or via `sudo` fails with `no $DISPLAY`.
- Known-bad transfer ISO documented; archive via File Bot (do not delete).

#### Device access

| File / setting | Change |
|----------------|--------|
| udev rules | USB / serial devices usable by the operator |
| RTL-SDR blacklist | Kernel DVB driver blacklisted |
| Operator groups | dialout (and related lab groups) |
| firewalld | Lab convenience zone (tighten before non-lab use) |

> Note: permissive device modes and firewall zones are lab conveniences for an isolated NAT guest. Tighten before any non-lab or bridged deployment.

### Design goals recorded

- SDR-agnostic image: no vendor-specific assumptions baked into the base guest.
- One USB filter **per SDR vendor** (not a catch-all filter).
- Later: headless node image for embedded units, then snapshot + OVA export for multi-device reuse.

## 2026-10-05 — Secondary RF package staged (not installed)

- Vendor freeware RF analysis package staged on removable media; requires matching vendor hardware (not RTL-SDR). Install queued after VM access work; snapshot first.
