> Scrubbed public copy. Mesh addresses, SSH account name, export-controlled keeper paths, and licence material are omitted; product-specific identifiers are generalised (`lab-*`, `<build-vm>`). Exact names are in the private team repo.

# TROUBLESHOOT: Rotre lab images

Use this when something does not work after flashing or rebuilding. Start at the top of each section.

---

## A. Computer will not boot from the flashed drive

1. Confirm you flashed a **spare** drive, not the Cyberdeck stick.
2. Open the boot menu (F12 / Esc / F10) and pick the USB drive.
3. Try both UEFI and “legacy” / CSM boot if the PC has both (image is hybrid GPT: biosboot + ESP).
4. **Secure Boot:** if the PC only allows signed OS disks, turn Secure Boot **off** for lab testing, or use a PC that allows it.
5. Disk too small: need **≥ 24 GiB** usable (raw image is 25769803776 bytes). Prefer ≥ 32 GB SSD.
6. Re-check the file hash vs `SHA256SUMS`. A bad copy makes strange boot failures.
7. Re-flash with Etcher. Do not pull the cable early.

## B. First boot hangs or “grow failed”

1. Leave it alone for 10–15 minutes. `growpart` + `xfs_growfs` on the last GPT partition is slow on cheap USB.
2. Do not power off mid-grow.
3. Check `/var/log/lab-firstboot.log` if you can mount the disk from another machine.
4. If stuck more than 20 minutes with no disk activity, power off, re-flash, try a different SSD.
5. On a VM test, give the virtual disk at least 32 GB.

## C. Ground boots but no desktop / no auto-login

1. Wait; GNOME can be slow on first boot.
2. If you only get a text login, you may have flashed **hab** or **uas** by mistake.
3. Lab auto-login is only on **ground**. Hab/uas are headless on purpose (`multi-user`, gdm/gnome/X removed).

## D. No network / wrong NIC / no mesh IP

1. Check EFI `lab\node.conf` or `/etc/lab-node/node.conf`. Effective result: `/etc/lab-node/effective.conf`.
2. Netconfig **0.2.0-draft**: unknown keys → exit 2 → network **unchanged**. Only use allowed keys (see flash HOW-TO).
3. `IFACE=auto` skips VirtualBox NAT PCI `0000:00:03.0` and any NIC in `10.0.2.x`.
4. Confirm the VM NIC is on the right intnet (`lab-mesh-ground` / `lab-mesh-hab` / `lab-mesh-uas`) and expected MAC if set.
5. Defaults if seed missing: gnd-01 `*(lab mesh)*`, hab-01 `*(lab mesh)*`, uas-01 `*(lab mesh)*`.
6. Hab/uas: DHCP first, then fallback static (~`FALLBACK_TIMEOUT`; hub DHCP must be up or wait for fallback).
7. Old images with netconfig **0.1.0** reject new keys (`CPU_POWER_CAP_W`, etc.). Use current Rotre files or remove those keys.

## E. SSH will not connect

1. User is the lab account (name in private docs). Password login is off — you need the **lab private key**. Root login is off.
2. Lab VM ports (confirm on your PC): build ground 2223, Build-HAB 2227, Build-UAS 2228; tests ground ~2231, hab 2229, uas 2230.
3. First boot remakes SSH host keys (`ssh-keygen -A`). Clear your old `known_hosts` line if warned.
4. System “degraded” right after first boot on **old** images = SSH keygen race. Current **r5 / r5b** order firstboot before `sshd-keygen@*`. Re-flash current Rotre files.

## F. No SDR / radio not seen

1. Plug the dongle directly into the machine (avoid bad hubs).
2. Kernel blacklist: `dvb_usb_rtl28xxu` (so RTL-SDR is claimed by the right driver).
3. Ground: check device list in desktop SDR++ / tools after login.
4. Hab/uas: streams **on request** (`STREAM_DEFAULT=none`). Units `stream-sdrpp` / `rtltcp` / `soapy` are **disabled** at boot. Use lab stream helpers after SSH.
5. Localrepo RPMs in image: hackrf 2026.01.3, airspyone_host 1.0.10, airspyhf 1.6.8, libiio 0.26, libad9361-iio 0.3, sdrpp 1.3.0 (cyberdeck.el10 builds). EPEL: rtl-sdr, SoapySDR.
6. **SoapyRemote not in EPEL 10** → soapy stream unit stays inactive (expected).
7. Brand-new dongle needing a newer driver = rebuild task (update localrepo + pipeline).

## G. The controlled RF app says it needs a licence / will not start

1. Normal. Images ship **without** the vendor licence file (and without add-on licences).
2. Install the licence on that machine only (never commit it to git; never put it in the controlled tarball used for rebuild).
3. Hab/uas: `lab-headless.service` stays inactive until the licence is present.
4. Ground lab may still show manager ports; licence still required for full use.
5. generalize **exits 3** if a licence / `*.lic` is still on the build VM — remove it before generalizing.

## H. Tailscale

1. Installed in base step 4, **not** joined. State is cleared at generalize.
2. To join: put a pre-auth key in a **file**, set `TS_AUTHKEY_FILE=` in `node.conf` to that path, reboot. Do not paste the key into git or docs.
3. generalize fails (exit 3) if Tailscale `tskey` material is still on the build VM.

## I. Mesh tests fail (hab link / contested / cut)

1. Confirm emu-01 (`*(lab emulator)*`) and hub-01 (`*(lab hub)*`) are running on the lab mesh.
2. Restore a clean profile: `meshctl profile good all` (see `Docs\NETWORK-SOP.md`).
3. Contested profile uses bursty loss on purpose — high ping loss can be expected.
4. Wrong intnet or MAC → wrong NIC / no mesh (see D).

## J. Rebuild / pipeline failures

| Symptom | Likely fix |
|---------|------------|
| Snapshot while VM was running | Power off, retake snapshot **offline** |
| Linked clone broken | You deleted/merged **base-provisioned** — restore from backup |
| Booted build VM after generalize | Firstboot fired — restore `*-lab-provisioned` and re-run from step 8 |
| generalize exit 3 | Remove licence / `*.lic` / tskey / Guest Additions / foreign keys / `99-lab-devices.rules` |
| Export hash mismatch | Re-run step 9; do not hand-edit images |
| Hab “degraded” after first boot (old image) | Use Rotre hab/uas **r5b** |
| Soapy stream inactive | Expected on Rocky 10 (no SoapyRemote in EPEL) |
| Wrong generalize path | Use `pipeline\base\generalize.sh` |


## L. Radio checks (after flash)

No live dongle in typical VM tests yet (USB filter may hold the RTL-SDR on the host).

**Without hardware (expected):**

- ground: `sdrpp --help` returns 0; `hackrf_info` runs (no board); controlled RF app manager ports on ground only.
- hab/uas: MQTT stream-req for rtltcp start → clean failure when no device; SoapyRemote unit inactive on Rocky 10 (not in EPEL); controlled RF app without licence → “unable to find license key file”; headless unit stays inactive until licence path exists.
- Ground r5+: mosquitto **clients** present, service masked. (Older ground r4 lacked clients — use r5+.)

**With hardware (bare metal / when dongle free):**

1. `lsusb` / `rtl_test -t` / `hackrf_info`
2. `sdrpp --server` (or lab stream CLI on headless)
3. Controlled RF app Soapy setup: enable RTL; put licence on the **target** (not baked into the image)
4. Ground: MQTT publish to `lab/<role>/<node>/status`

Keep blacklist: `dvb_usb_rtl28xxu`.


## M. Known image regressions (fixed in current Rotre)

| Issue | When | Status |
|-------|------|--------|
| sshd refused host keys (0640) | ground r1 | firstboot 0600 + `sshd -t` → r2+ |
| netconfig missed virtio NAT PCI | r2 | IFACE=auto virtio path → r3+ |
| NAT no DHCP after generalize | r3 | `90-lab-auto-default.conf` → r4+ |
| Dual xz export OOM | Job4 | `-XzThreads 8` |
| Agent NoNewPrivileges / chronyc | HAB r5 | removed; agent 0.1.1-lab → r5b |
| firstboot vs sshd-keygen race | HAB r5 | `Before=sshd-keygen@*` → r5/r5b |
| build.ps1 `-Tag` skipped step 8 | early r5b | Tag suffix logic fixed |
| SoapyRemote missing EPEL 10 | headless | soapy unit inactive (expected) |
| Live RTL-SDR in VM | all | PENDING bare metal |
| Secure Boot on target | — | untested |
| Localrepo unsigned / release-hardening not run | known | required before non-lab deploy |
| mosquitto clients missing on ground | r4 | use ground r5+ |

## K. Still stuck

1. Grab: role (ground/hab/uas), exact file name, hash check result, photo/screenshot of the error.
2. Note UEFI vs BIOS, and whether this is a VM or bare metal.
3. Optional: `/var/log/lab-firstboot.log` and `/etc/lab-node/effective.conf`.
4. Hand that to the lab owner / Cyber team. Do not post controlled image files outside the approved places.

Related docs: `HOW-TO-Rotre-Flash.md`, `HOW-TO-Rotre-From-Scratch.md`, `NETWORK-SOP.md`, each folder’s `BUILD-INFO.txt`.
