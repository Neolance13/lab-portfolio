> Scrubbed public copy. Mesh addresses, SSH account name, export-controlled keeper paths, and licence material are omitted; product-specific identifiers are generalised (`lab-*`, `<build-vm>`). Exact names are in the private team repo.

# HOW-TO: Flash a Rotre lab image

**Read this before you click anything.** Flashing the wrong drive will erase that drive forever.

Lab image only. Keep it on this PC and the Cyberdeck stick. Do not upload it.

---

## 1. What you need

1. The Cyberdeck USB stick that already has the Rotre folders.
2. A **spare** USB SSD (or USB drive) that is **at least 32 GB**. You will wipe this drive. (Image is 24 GiB raw; need room to grow.)
3. A Windows PC with [balenaEtcher](https://etcher.balena.io/) (easiest) or Rufus.
4. About 20 minutes. First boot is slow on purpose.

## 2. Pick the right image

| Folder | Use when |
|--------|----------|
| `ground` | Desk computer with a screen (auto-login) |
| `hab` | Balloon computer (no screen; SSH only) |
| `uas` | Drone computer (no screen; SSH only) |

On the stick (current label **v0.1.0-2026-10-06**):

```
`(USB kit) Images/Rotre/v0.1.0-…/ground/`
`(USB kit) Images/Rotre/v0.1.0-…/hab/`
`(USB kit) Images/Rotre/v0.1.0-…/uas/`
```

File name looks like:

`rotre-ground-lab-v0.1.0-2026-10-06.img.xz`

Optional check (PowerShell), compare to `SHA256SUMS` in the same folder:

```
Get-FileHash .\rotre-ground-lab-v0.1.0-2026-10-06.img.xz -Algorithm SHA256
```

## 3. Flash with balenaEtcher

1. Plug in the **spare** USB SSD only. Do **not** flash the Cyberdeck stick itself.
2. Open balenaEtcher.
3. Click **Flash from file**. Open the `.img.xz` for ground, hab, or uas. Etcher reads `.xz` as-is.
4. Click **Select target**. Pick the spare SSD. Check the size so you know it is the right one.
5. Click **Flash**. Wait until it says finished. Do not unplug early.
6. Eject the flashed drive safely.

Rufus also works with `.xz` on current Rufus 4.x. Same rule: pick the spare drive carefully.

## 4. First boot (what happens)

1. Plug the flashed drive into the test computer.
2. Power on. Open the boot menu (**F12**, **Esc**, or **F10** on many PCs).
3. Choose the USB drive. UEFI or older BIOS both work (hybrid GPT).
4. Wait. First boot can take several minutes. **Do not power off.**

On first boot the image runs **lab-firstboot** once (`/etc/lab-firstboot.pending`):

- Grows the root partition (`growpart` + `xfs_growfs` on the **last** GPT partition).
- Makes a new `machine-id`.
- Runs `ssh-keygen -A` (keys `0600` root:root on EL10) and `sshd -t`.
- Sets hostname to `lab-<first 4 hex of machine-id>` unless `HOSTNAME` is set in `node.conf`.
- Regenerates `/etc/brlapi.key` if brlapi is present.
- Logs to `/var/log/lab-firstboot.log`.

Current r5 / r5b images order firstboot **before** `sshd-keygen@rsa/ecdsa/ed25519` so SSH keys are not raced (fixes older “degraded” boots).

5. **Ground:** you should land on the desktop (auto-login).  
6. **hab / uas:** no desktop. SSH as the lab account with the lab key.

### Default lab network (if you do not change `node.conf`)

| Role | Hostname | Mesh address | Mode |
|------|----------|--------------|------|
| ground | gnd-01 | *(lab mesh address — private)* | static |
| hab | hab-01 | *(lab mesh address — private)* | DHCP, then fallback static |
| uas | uas-01 | *(lab mesh address — private)* | DHCP, then fallback static |

Lab uses a private flat mesh (addressing in the private NETWORK-SOP). Core examples: hub-01 `*(lab hub)*`, emu-01 `*(lab emulator)*`.

## 5. Change the network (optional)

Netconfig version **0.2.0-draft**. Precedence:

1. `/boot/efi/lab/node.conf` (EFI FAT — edit from Windows)  
2. `/etc/lab-node/node.conf`  
→ writes `/etc/lab-node/effective.conf`

On Windows: open the flashed drive’s **EFI** partition → `lab\` → copy `node.conf.example` to `node.conf` if needed → edit in Notepad → save **UTF-8** → eject → reboot. Netconfig runs every boot. Invalid conf = exit 2 → network left unchanged.

**Allowed keys only** (strict whitelist; unknown keys = invalid):

`ROLE` `NODE_ID` `HOSTNAME` `DOMAIN` `NET_MODE` `IFACE` `ADDRESS` `PREFIX` `GATEWAY` `DNS` `NTP` `MQTT_HOST` `TS_AUTHKEY_FILE` `FALLBACK_TIMEOUT` `CPU_POWER_CAP_W` `WATCHDOG_SEC` `STREAM_DEFAULT` `RECORD_MAX_PCT`

**`IFACE=auto`:** first wired Ethernet (natural sort) with a bus device; **skips** VirtualBox NAT PCI `0000:00:03.0` (including virtio under it) and any NIC with `10.0.2.x`.

### Address formula (*(lab mesh address — private)*)

Addressing formulas live in the **private** NETWORK-SOP (not published here).


| Block | Role | Formula | Example |
|-------|------|---------|---------|

Hab/uas default power caps in seed: `CPU_POWER_CAP_W=12` (hab), `8` (uas).

## 6. After it boots (quick checks)

**Ground**

- Desktop appears.
- Plug an RTL-SDR if you have one; see **TROUBLESHOOT-Rotre.md** if missing.

**Hab / uas**

```
ssh -i <lab-key> -p <port> <lab-user>@<host>
```

Lab VM port forwards (confirm on your PC): ground test ~2231, hab ~2229, uas ~2230. On real hardware use the mesh IP.

- Tailscale is installed but **not** joined until `TS_AUTHKEY_FILE=` points at a key **file** in `node.conf`.
- The controlled RF app needs its vendor licence file on each machine. The image does **not** include one. Hab/uas `lab-headless.service` stays inactive without it.
- Streams start **on request** (`STREAM_DEFAULT=none`); stream units are disabled at boot.

## 7. Warnings

- Wrong target drive = that drive is wiped.
- Lab image = easy login settings. Do not ship as a release.
- Export-controlled software inside — local and stick only.