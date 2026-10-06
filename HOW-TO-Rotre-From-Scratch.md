> Scrubbed public copy. Mesh addresses, SSH account name, export-controlled keeper paths, and licence material are omitted; product-specific identifiers are generalised (`lab-*`, `<build-vm>`). Exact names are in the private team repo.

# HOW-TO: Rebuild Rotre from scratch (lab)

**Who this is for:** someone who must rebuild the lab disk image if the USB copy is lost or broken.
**Reading level:** plain steps. Follow in order. Do not skip.
**Export control:** these images include controlled radio software. Keep files on this PC, the Cyberdeck stick, and the local backup only. Never upload to the public internet or a public git repo. No product license is baked into the image.

Lab builds only — not a release.
Product name: **Rotre**. Pipeline folders still use an internal working name until renamed. Shipping layout:

`Images\Rotre\v0.x.x-YYYY-MM-DD\{ground,hab,uas}\rotre-<role>-lab-v0.x.x-YYYY-MM-DD.img.xz`

Current label: **v0.1.0-2026-10-06** (ground = r5, hab/uas = r5b).

---

## 0. What you need before you start

1. Windows PC with VirtualBox 7.2.x + Extension Pack.  
   `VBoxManage` on the build PC PATH / VirtualBox install
2. About 60 GB free on `D:`.
3. Internet (Rocky / EPEL, GitHub tarballs, Tailscale repo).
4. Rocky Linux **10.2** DVD ISO:  
   `(local Rocky 10.2 DVD ISO — path private)`
5. Controlled RF app installed-tree tarball (**local only**, never in any repo, **no licence**):  
   `(local controlled keeper tarball — path private; never commit)`  
   (hash recorded in private BUILD-INFO only).  
   Rebuild tree must not include any licence or private keys.
6. Build folder: `(lab pipeline folder on the build PC — private repo documents the layout)`
7. Lab SSH public key staged the way the pipeline expects (ask the lab owner if unsure).

**Never delete or merge** the VirtualBox snapshot **base-provisioned**. Hab/uas build VMs are linked clones of it.

**Never boot the build VM after generalize** — firstboot would fire. To change the image, restore the `*-lab-provisioned` snapshot instead.

---

## 1. Big picture

```
Rocky 10.2 ISO + kickstart (base.ks)
        |
   shared BASE (steps 1–6) → snapshot base-provisioned
        |
   +-- ground  (desktop + auto-login lab mode)
   +-- hab     (headless balloon; linked clone)
   +-- uas     (headless drone; linked clone + slim)
        |
   generalize → export .img.xz → flash
```

---

## 2. Pipeline driver

```
cd <project-root>\Projects\<image-project>\pipeline
.\build.ps1 -Profile ground|hab|uas -From N -To M -Tag <tag>
```

Defaults: `-From 1 -To 10`. **Export = step 9.**

| Step | What | Snapshot / marker |
|------|------|-------------------|
| 1 | Create build VM (EFI, 24576 MB VDI, NAT SSH) | VM registered |
| 2 | OEMDRV kickstart ISO + unattended install from Rocky DVD | — |
| 3 | Power off, offline snapshot | `base-installed` |
| 4 | Base layer (`post-install-base.sh` + Tailscale **install only**) | `/etc/cyberdeck-base-layer` |
| 5 | Build SDR RPMs → guest `/opt/cyberdeck/localrepo` + host `<project-root>\Installers\RF\localrepo` | NVR skip if present |
| 6 | Controlled RF app tree (**no licence**) + SDR++; offline snapshot | **`base-provisioned`** |
| 7 | Profile + `lab-mode.sh` | `<profile>-lab-provisioned` |
| 8 | Profile delta + `post-install-node.sh` + `generalize.sh --poweroff` | `<profile>-generalized-<date>[-Tag]` |
| 9 | `tools\export-image.ps1` | `SHA256SUMS` / `BUILD-INFO` |
| 10 | `tools\test-image.ps1` (create / efi / bios / off) | per-profile test VM |

### Normal rebuild commands

Shared base (once):

```
.\build.ps1 -Profile ground -From 1 -To 6
```

Then per role (use a new `-Tag` for a new rebuild):

```
.\build.ps1 -Profile ground -From 7 -Tag r5
.\build.ps1 -Profile hab    -From 7 -Tag r5b
.\build.ps1 -Profile uas    -From 7 -Tag r5b
```

Hab/uas step 7: linked clone of `base-provisioned` + `BASE_UPGRADE=0` `post-install-base.sh` (generic dracut) then profile.

---

## 3. Profile VMs / ports / seeds

| Profile | Build VM | SSH | Seed node.conf | Test VM | Test port | Mesh intnet / MAC |
|---------|----------|-----|----------------|---------|-----------|-------------------|
| ground | `<build-vm>` | 2223 | ground-gnd-01 | `<test-vm>` | 2226 / 2231 | lab-mesh-ground / *(lab MAC — private)* |
| hab | Build-HAB (linked clone) | 2227 | hab-hab-01 | Test-HAB[-Tag] | 2229 | lab-mesh-hab / *(lab MAC — private)* |
| uas | Build-UAS | 2228 | uas-uas-01 | Test-UAS[-Tag] | 2230 | lab-mesh-uas / *(lab MAC — private)* |

---

## 4. Kickstart (what the base disk looks like)

File: `pipeline\kickstart\base.ks` — Rocky **10.2**, `#version=RHEL10`.

GPT layout (no LVM, no swap; zram later):

1. biosboot 1 MiB  
2. ESP 600 MiB  
3. `/boot` 1 GiB xfs  
4. `/` xfs grow (**last** partition — firstboot grows it)

`@core` + UEFI/BIOS hybrid. Root locked; `<lab-user>` locked + wheel + lab SSH pubkey only. Groups later: `lab`, `plugdev`; `rtlsdr` from EPEL `rtl-sdr`.

---

## 5. Packages the base puts on

**High-level:** CRB + EPEL; `rtl-sdr`, SoapySDR, volk/glfw/portaudio; zram-generator; blacklist `dvb_usb_rtl28xxu`; local SDR RPMs; controlled RF app from its local tarball **without** licence.

**Localrepo RPMs** (`(local SDR RPM repo)`):

- `hackrf-2026.01.3-1.cyberdeck.el10` (+ devel, firmware noarch)
- `airspyone_host-1.0.10-1.cyberdeck.el10` (+ devel)
- `airspyhf-1.6.8-1.cyberdeck.el10` (+ devel)
- `libiio-0.26-1.cyberdeck.el10` (+ devel, utils)
- `libad9361-iio-0.3-1.cyberdeck.el10` (+ devel)
- `sdrpp-1.3.0-2.20260704git8c9f5ee8.cyberdeck.el10`

EPEL: `rtl-sdr`, SoapySDR. **SoapyRemote is not in EPEL 10** → soapy stream unit stays inactive (expected).

Scripts: `pipeline\base\post-install-base.sh`, `post-install-sdrpp.sh`, `post-install-rfapp.sh`, `post-install-tailscale.sh`, `build-sdr-rpms.sh`.

---

## 6. Profile differences

| | ground | hab | uas |
|---|--------|-----|-----|
| Target | graphical (`graphical-server-environment`), GDM | multi-user via `headless/install-headless.sh` ROLE=hab | same ROLE=uas + slim |
| GUI | GNOME + controlled RF app launcher + SDR++ GUI | none (remove gdm/gnome/X) | none |
| mosquitto | clients; service **masked** | same | same |
| Agent / streams | no agent | lab-node-agent 0.1.1-lab; streams on request; powercap / watchdog / record / headless | same |
| Extra | favourites dconf | embedded SBC / MANET radio notes; `CPU_POWER_CAP_W=12` | remove cockpit/brltty; docs emptied; firmware trim; `CPU_POWER_CAP_W=8` |
| Size (r5b class) | see BUILD-INFO | ~8022 MB / ~575 RPMs | ~7730 MB / ~565 RPMs (−292 MB) |

**Headless units enabled:** agent, powercap, watchdog, headless (inactive without licence), record-prune.timer.  
**Disabled:** stream-sdrpp / rtltcp / soapy, record, labmgr, cockpit, mosquitto, gdm.  
User `lab-sdr` (nologin).

---

## 7. What “generalize” does

Path: **`pipeline\base\generalize.sh`** (not `pipeline\generalize.sh`).

Run only on the build VM, as root, right before the offline snapshot (pipeline step 8 does this with `--poweroff`):

```
GENERALIZE_CONFIRM=yes bash /path/to/generalize.sh
```

**Fails with exit 3 if it finds:** licence / `*.lic`, `99-lab-devices.rules`, Tailscale `tskey` material, foreign private keys, Guest Additions / hypervisor agents.

**Removes:** `zz-build-<lab-user>`; Tailscale state; cockpit certs; `/etc/brlapi.key`; NM connections/leases; hostname; netconfig derived; SSH host keys; empty machine-id; histories/caches/logs; stream state.

**Re-arms** `/etc/lab-firstboot.pending`. Requires `90-lab-auto-default.conf` present. Keeps lab sudoers / lab account + seeded `node.conf`.

Lab conveniences stay until `release-hardening.sh` before any real field use.

---

## 8. Export (step 9)

`tools\export-image.ps1` writes under:

`(local Images/… export folder — private)`<date>[-Tag]\Rocky10-SDR-<profile>-<date>.{img,img.xz,vdi,ova}`

plus `SHA256SUMS` / `SHA256SUMS.<profile>-lab` and `BUILD-INFO[-profile].txt`.

- Raw `.img` = **25769803776** bytes (24 GiB).  
- Default `-XzThreads 8`.  
- OVA product string: `Rocky10-SDR <profile> (LAB build, NOT a release image)`.

After export, docs owner renames/copies into the **Rotre** shipping layout (hashes unchanged).

### Current flashables (hashes truncated in BUILD-INFO; verify full SHA256SUMS)

| Role | Source folder | Notes |
|------|---------------|-------|
| ground | `...\2026-10-05-r5\Rocky10-SDR-ground-lab-2026-10-05.img.xz` | → Rotre ground |
| hab | `...\2026-10-05-r5b\Rocky10-SDR-hab-lab-2026-10-05.img.xz` | → Rotre hab |
| uas | `...\2026-10-05-r5b\Rocky10-SDR-uas-lab-2026-10-05.img.xz` | full SHA256 in private SHA256SUMS |

Keep superseded r5 hab/uas and ground r4 under `2026-10-05\` / Archive as already done.

---

## 9. After a successful rebuild

1. `Get-FileHash … -Algorithm SHA256` vs `SHA256SUMS`.
2. Copy into `Images\Rotre\v0.x.x-YYYY-MM-DD\{ground,hab,uas}\`.
3. Mirror to the portable stick and the second local copy.
4. Flash a spare disk — see **HOW-TO-Rotre-Flash.md**.
5. Failures — see **TROUBLESHOOT-Rotre.md**.

---

## 10. Do not do these things

- Do not put images or the controlled RF app tarball in Drive or any public repo.
- Do not generalize with a licence still on the VM.
- Do not delete `base-provisioned`.
- Do not boot the build VM after generalize.
- Do not treat lab images as a release (run hardening first).

Source of truth: `pipeline\README.md`, `pipeline\build.ps1`, `PROGRESS-2026-10-05.md`, each role’s `BUILD-INFO.txt`, lab build notes 2026-10-06.