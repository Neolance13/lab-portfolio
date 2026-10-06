# CMD-REFERENCE (command cipher)

Every command and CLI step used in the public lab guides, in one place, grouped by task. Scrubbed copy: hosts, accounts, addresses, paths and the tailnet are placeholders, and the controlled RF software is described generically. The team's private docs hold the full-detail version.

**Standing rule: every newly documented command is added here** (same columns, right group) in the same doc pass that documents it.

## How to use it (cross-check)

1. Before you type a command from any HOW-TO, find it here. Check **Runs on** (wrong shell = wrong result) and read **Caution**.
2. Anything marked **DESTRUCTIVE**, **FIREWALL CHANGE**, **ACCESS-CONTROL CHANGE**, **NETWORK EXPOSURE**, **PERMISSION CHANGE** or **FORBIDDEN** needs a snapshot/backup first and, for deletes or exposure, approval through Ghost Lead.
3. If a doc shows a command that is not in this table, or the two disagree, stop and tell File Bot - the docs get fixed, then this table.
4. **Used in** names the doc(s) where the command appears. "(implied)" means the doc describes the step in words and this row gives the matching command.

**Runs on:** `Windows PowerShell` = the lab PC (PowerShell 5). `Rocky bash` = a Rocky Linux guest/node shell (most also work on any Linux). `either` = same command on both. `Windows (GUI)` = a click path, not a typed command.

**Placeholders:** `<file>`, `<path>`, `<vm>`, `<port>`, `<user>`, `<lab-user>`, `<lab-key>`, `<if>` / `<port>` (NIC), `<hub>`, `<tag>`, `<N>`/`<M>` (pipeline step numbers). Replace the whole `<...>` including the brackets. Secrets (keys, passwords, auth keys) are never written into a command in any doc - they live in the local Secrets file only.


**Totals:** 128 commands in 9 groups.


## Groups

- [Flash / imaging](#flash--imaging) (16)
- [Tailscale](#tailscale) (13)
- [SSH / SFTP](#ssh--sftp) (10)
- [VirtualBox](#virtualbox) (15)
- [SDR / RF](#sdr--rf) (16)
- [Network](#network) (40)
- [Git / publish](#git--publish) (11)
- [Files / backup](#files--backup) (4)
- [Other](#other) (3)

## Flash / imaging

| Command | What it does (plain words) | Runs on | Used in | Caution |
|---|---|---|---|---|
| `Get-FileHash <file> -Algorithm SHA256` | Prints the SHA-256 of a file so you can compare it with the line in SHA256SUMS before flashing or after copying. | Windows PowerShell | private team doc, HOW-TO-Rotre-Flash, HOW-TO-Rotre-From-Scratch | Read-only. |
| `certutil -hashfile <file> SHA256` | Same hash check with the built-in certutil tool (works in cmd too). | Windows PowerShell | private team doc | Read-only. |
| `sha256sum -c --ignore-missing SHA256SUMS` | Checks every file listed in SHA256SUMS that is present in the folder; prints OK or FAILED per file. | Rocky bash | private team doc | Read-only. Any FAILED = do not flash. |
| `balenaEtcher: Flash from file -> Select target -> Flash` | Writes a Rotre .img.xz straight to a USB stick or SSD (Etcher reads .xz as-is). | Windows (GUI) | HOW-TO-Rotre-Flash, private team doc, TROUBLESHOOT-Rotre, HOWTO-Rocky-SDR-VM | **DESTRUCTIVE** - erases the whole target drive. Pick the spare drive only; never the system disk or the kit USB. Do not pull the cable early. |
| `Rufus 4.x: select .img.xz -> write in DD image mode` | Alternative flasher; Rufus 4.x also reads .img.xz directly. | Windows (GUI) | HOW-TO-Rotre-Flash, private team doc, HOWTO-Rocky-SDR-VM | **DESTRUCTIVE** - erases the whole target drive. Same drive-pick rule as Etcher. |
| `dd / wipefs (Linux raw disk tools)` | Not used by any Cyberdeck doc. Listed only so nobody reaches for them: flash with Etcher or Rufus instead. | Rocky bash | (this doc) | **DESTRUCTIVE** - one wrong device name wipes a disk. Do not use for Rotre flashing. |
| `cd <path>\pipeline` | Goes to the image build pipeline folder (all build.ps1 commands run from here). | Windows PowerShell | HOW-TO-Rotre-From-Scratch, README | Read-only. |
| `.\build.ps1 -Profile <ground/hab/uas> -From <N> -To <M> -Tag <tag>` | General form: runs pipeline steps N to M for one role and tags the output (e.g. r5, r5b). | Windows PowerShell | HOW-TO-Rotre-From-Scratch, README | Creates / changes build VMs and snapshots; long run. Never delete or merge snapshot base-provisioned (KI-23). |
| `.\build.ps1 -Profile ground -From 1 -To 6` | Builds the shared base once (steps 1-6: kickstart install, base packages, SDR RPMs, RF app tree with no licence) and takes snapshot base-provisioned. | Windows PowerShell | HOW-TO-Rotre-From-Scratch, README | Long run; base-provisioned is the parent of the HAB/UAS linked clones (KI-23). |
| `.\build.ps1 -Profile <ground/hab/uas> -From 7 -Tag <tag>` | Builds one role from step 7 to the end (profile, generalize, export). Current tags: ground r5, hab r5b, uas r5b. | Windows PowerShell | HOW-TO-Rotre-From-Scratch, README | Ends in generalize + export; do not boot the build VM afterwards. |
| `.\build.ps1 -Profile hab -From 7 -To 10 -Tag r5b` | Slice example: runs only steps 7-10 for one role. | Windows PowerShell | README | - |
| `.\build.ps1 -Profile ground -From 9 -To 9 -Tag r5` | Export only (re-runs just the export step). | Windows PowerShell | README | Overwrites that tag's export files if they exist. |
| `.\build.ps1 ... -XzThreads 8` | Caps xz compression threads (default 8) so two exports at once do not run out of memory. | Windows PowerShell | HOW-TO-Rotre-From-Scratch, TROUBLESHOOT-Rotre | - |
| `GENERALIZE_CONFIRM=yes bash <path>/generalize.sh` | Wipes machine identity (machine-id, SSH host keys, network state, Tailscale state) so the disk can be cloned. Real path: pipeline/base/generalize.sh. Refuses if licence/key material remains. | Rocky bash | HOW-TO-Rotre-From-Scratch, TROUBLESHOOT-Rotre, README | **DESTRUCTIVE to the VM's identity.** Build VM only, right before export. Never on a live node; never boot the build VM after it. |
| `generalize.sh --poweroff` | Pipeline step 8 form: generalize, then power the VM off for export. | Rocky bash | HOW-TO-Rotre-From-Scratch | **DESTRUCTIVE to the VM's identity** (same as above). |
| `growpart <disk> <part> + xfs_growfs /` | Grows the root partition and filesystem to fill the drive. Runs by itself on first boot (last GPT partition). | Rocky bash | HOW-TO-Rotre-Flash, TROUBLESHOOT-Rotre | Changes the partition table. Automatic on first boot; slow on cheap USB - wait 10-15 min, do not pull power. Do not run by hand on another disk. |

## Tailscale

| Command | What it does (plain words) | Runs on | Used in | Caution |
|---|---|---|---|---|
| `tailscale status` | Lists the devices on the tailnet, their 100.x addresses and whether they are online. First check for any VPN problem. | either | HOW-TO-Tailscale-Lab, private team doc | Read-only. |
| `tailscale ip -4` | Shows this device's own 100.x tailnet address. | either | HOW-TO-Tailscale-Lab | Read-only. Addresses go in local Secrets, not docs. |
| `sudo dnf config-manager --add-repo https://pkgs.tailscale.com/stable/rhel/10/tailscale.repo` | Adds the official Tailscale package repo on Rocky 10. | Rocky bash | private team doc | - |
| `sudo dnf install tailscale` | Installs Tailscale from that repo. | Rocky bash | private team doc | - |
| `sudo systemctl enable --now tailscaled` | Starts the Tailscale service now and at every boot. | Rocky bash | private team doc, HOWTO-Rocky-SDR-VM | - |
| `sudo tailscale up --auth-key=<tagged-key> --ssh` | Joins the tailnet with a pre-made tagged auth key and turns on Tailscale SSH. | Rocky bash | private team doc | **SECRET** - the auth key is a credential: never type it into docs or chat; prefer the file: form below. |
| `sudo tailscale up --auth-key=file:<path> --hostname=<HOSTNAME> --accept-dns=false --accept-routes=false` | Node opt-in join used by the lab join helper: reads the key from a root-only file, sets the name, ignores tailnet DNS and routes. | Rocky bash | NETWORK-SOP | **SECRET** - key file stays local, root-only, never in an image or repo. |
| `tailscale up --ssh` | Turns on Tailscale SSH (also needs an ssh rule in the tailnet policy). | Rocky bash | private team doc | Opens SSH to whoever the policy allows - check the policy first. |
| `tailscale up --ssh --advertise-tags=tag:mirror` | Joins the planned mirror VM with tag:mirror so policy rules apply to it. | Rocky bash | private team doc | Tag must exist in tagOwners first. |
| `tailscale up --advertise-routes=<lan-cidr>` | Makes this box a subnet router so tailnet devices can reach a whole LAN (e.g. a radio or SDR on a lab LAN). | Rocky bash | private team doc | **NETWORK EXPOSURE** - exposes the whole LAN to the tailnet; needs admin approval; lab only. |
| `tailscale down` | Disconnects this device from the tailnet (stays logged in). | either | NETWORK-SOP | Cuts any remote session riding on Tailscale. |
| `ping <magicdns-name>` / `ping <100.x.y.z>` | Checks a tailnet device answers before trying SSH. | either | HOW-TO-Tailscale-Lab | Read-only. |
| `Admin console -> Access controls (tailnet policy JSON)` | Where tags, grants and ssh rules live (examples in the INNO briefs). | Windows (GUI) | private team doc | **ACCESS-CONTROL CHANGE** - a bad grant opens ports to everyone on the tailnet. Ghost Lead approval. |

## SSH / SFTP

| Command | What it does (plain words) | Runs on | Used in | Caution |
|---|---|---|---|---|
| `ssh -i <lab-key> -p <port> <lab-user>@127.0.0.1` | SSH into a lab VM through its VirtualBox NAT port forward (localhost only). Each VM has its own forwarded port. | Windows PowerShell | HOW-TO-Rotre-Flash, HOWTO-Rocky-SDR-VM, NETWORK-SOP | Key-only. Key file stays in local Secrets. |
| `ssh <user>@<magicdns-name-or-100-ip>` | SSH to a lab node over the tailnet (user and name as shown in tailscale status). | either | HOW-TO-Tailscale-Lab | Lab tailnet only; never the personal tailnet. |
| `sftp <user>@<magicdns-name-or-100-ip>` | Opens an SFTP file session over the tailnet. | either | HOW-TO-Tailscale-Lab | - |
| `put <local-file> /home/<user>/` | (inside sftp) Uploads a file to the node. | either | HOW-TO-Tailscale-Lab | Overwrites a same-name remote file. Never send ITAR files off the lab nodes. |
| `get /home/<user>/<remote-file> <local-folder>` | (inside sftp) Downloads a file from the node. | either | HOW-TO-Tailscale-Lab | Overwrites a same-name local file. |
| `ssh-keygen -A` | Creates any missing SSH host keys (first boot does this after generalize). | Rocky bash | HOW-TO-Rotre-Flash, TROUBLESHOOT-Rotre | New host keys = clients see a changed-key warning; clear the old known_hosts line. |
| `ssh-keygen -R "[127.0.0.1]:<port>"` | Removes the old known_hosts line for a re-flashed or rebuilt node (the fix for the changed-key warning). | either | TROUBLESHOOT-Rotre (implied) | Only for a host you know was rebuilt - a surprise key change can mean a wrong host. |
| `sshd -t` | Tests the SSH server config and host keys; silent = OK. | Rocky bash | HOW-TO-Rotre-Flash, TROUBLESHOOT-Rotre | Read-only. |
| `systemctl status sshd` | Shows whether the SSH server is running on a node (check when ping works but SSH fails). | Rocky bash | HOW-TO-Tailscale-Lab (implied) | Read-only. |
| `sudo visudo -c` | Checks all sudoers files for syntax errors. | Rocky bash | HOWTO-Rocky-SDR-VM, PATCHNOTES, CHANGELOG | Read-only. Always run after touching /etc/sudoers.d/. |

## VirtualBox

| Command | What it does (plain words) | Runs on | Used in | Caution |
|---|---|---|---|---|
| `VBoxManage list vms` | Lists registered VMs with their UUIDs. | Windows PowerShell | NETWORK-SOP, PATCHNOTES | Read-only. |
| `VBoxManage showvminfo <vm> [--machinereadable]` | Full VM config: NICs (incl. adapter 5 the GUI hides), disk paths, snapshots, linked children. | Windows PowerShell | NETWORK-SOP, KNOWN-ISSUES, private team doc | Read-only. Check it before any snapshot or disk cleanup (KI-23). |
| `VBoxManage list systemproperties` | Host VirtualBox limits (e.g. 8 NICs per VM on PIIX3, 36 on ICH9). | Windows PowerShell | NETWORK-SOP | Read-only. |
| `VBoxManage modifyvm <vm> --natpf1 "ssh,tcp,127.0.0.1,<port>,,22"` | Adds an SSH port forward on NIC 1 (VM powered off). Example: main VM uses 2222. | Windows PowerShell | HOWTO-Rocky-SDR-VM | Bind 127.0.0.1 only - never leave the host IP blank / 0.0.0.0. |
| `VBoxManage controlvm <vm> natpf1 "ssh,tcp,127.0.0.1,<port>,,22"` | Same port forward on a running VM. | Windows PowerShell | HOWTO-Rocky-SDR-VM | Same 127.0.0.1 rule. |
| `VBoxManage modifyvm <vm> --nic5 <type> ...` | Sets adapter 5 (the GUI only shows 1-4); emu-01 needs it for mesh-uas. Exact args are in the lab VM plan script. | Windows PowerShell | NETWORK-SOP | VM powered off. Do not 'fix' emu-01 from the GUI afterwards. |
| `VBoxManage controlvm <vm> setlinkstate1 off` | Unplugs NIC 1 (NAT) on a running lab VM for the no-internet test (TS1). | Windows PowerShell | NETWORK-SOP | Cuts the NAT SSH path to that VM until set back on. |
| `VBoxManage controlvm <vm> usbattach <uuid-or-address>` | Attaches a host USB device (e.g. RTL-SDR) to a running VM. | Windows PowerShell | KNOWN-ISSUES | 'busy with previous request' = replug the device (KI-11). |
| `.\New-LabVMs.ps1 (lab VM plan script)` | Prints the VirtualBox plan for the emulator and hub VMs (5 NICs, MACs, NAT SSH forwards) without changing anything. | Windows PowerShell | NETWORK-SOP, private team doc | Read-only (print only). |
| `.\New-LabVMs.ps1 -IsoPath <Rocky10.iso> -Apply` | Creates the emulator and hub VMs for real. | Windows PowerShell | NETWORK-SOP, private team doc | Creates VMs; refuses existing and protected VMs. Review the print-only output first. |
| `VBoxManage export "<vm>" -o VMs/<vm>.ova` | Exports a VM to an OVA file (example in HOWTO: the main lab VM). | Windows PowerShell | HOWTO-Rocky-SDR-VM | Blocked until lab-only settings are reverted (KI-13). OVA is ITAR - local / USB / second copy only. |
| `VBoxManage movevm <vm> --folder=<dest>` | Moves a VM's folder (used to move the lab VM off a cloud-sync folder onto the local lab disk). | Windows PowerShell | BOT-SOP, FILING-SOP, README, KNOWN-ISSUES, LAB-TODO, PATCHNOTES | VM powered off; back up first; never move into OneDrive. |
| `VBoxManage clonemedium <src.vdi> <dst.vdi>` | Copies a .vdi disk with a new UUID (safe way to copy a disk image). | Windows PowerShell | private team doc | Needs free space for a full copy. |
| `VBoxManage snapshot <vm> delete <snapshot>` | Deletes / merges a snapshot. Not a routine step in any doc - listed for the warning. | Windows PowerShell | KNOWN-ISSUES (KI-23) | **DESTRUCTIVE** - never on base-provisioned of the build VM (breaks the HAB/UAS linked clones). Approval required. |
| `VBoxManage unregistervm <vm> --delete` | Removes a VM and deletes its disk files (used once, operator-approved, for two disposable test VMs). | Windows PowerShell | CHANGELOG, LAB-TODO, PATCHNOTES, TASK-REGISTRY, HOWTO-Rocky-SDR-VM | **DESTRUCTIVE / irreversible** - operator approval first; check for linked children with showvminfo. |

## SDR / RF

| Command | What it does (plain words) | Runs on | Used in | Caution |
|---|---|---|---|---|
| `cd ~/installers && chmod +x <rf-app>-linux-installer.run && ./<rf-app>-linux-installer.run` | Installs the controlled RF app from its local installer inside the guest (no sudo). | Rocky bash | HOWTO-Rocky-SDR-VM | ITAR installer - local / USB only. Licence key goes in local Secrets, never in an image. |
| `sudo dnf install epel-release` | Enables EPEL (source of rtl-sdr, SoapySDR, mosquitto). | Rocky bash | HOWTO-Rocky-SDR-VM | - |
| `sudo dnf config-manager --set-enabled crb` | Enables the CRB repo (needed for some build deps). | Rocky bash | HOWTO-Rocky-SDR-VM, CHANGELOG | - |
| `sudo dnf install rtl-sdr` | Installs the RTL-SDR tools (rtl_test etc.). | Rocky bash | HOWTO-Rocky-SDR-VM, KNOWN-ISSUES | - |
| `sudo udevadm control --reload-rules && sudo udevadm trigger` | Reloads udev rules after adding the lab device rule (99-lab-devices.rules). | Rocky bash | HOWTO-Rocky-SDR-VM, PATCHNOTES | The lab rule is mode 0666 (broad, KI-7) - tighten before shared use. |
| `sudo modprobe -r dvb_usb_rtl28xxu` | Unloads the TV-tuner driver so the RTL-SDR is free (blacklisted in /etc/modprobe.d/rtl-sdr-blacklist.conf). | Rocky bash | PATCHNOTES | Harmless if not loaded. |
| `sudo usermod -aG wheel,dialout,<rf-app-group> <user>` | Adds the user to admin (wheel), serial (dialout) and RF app groups. Log out and back in after. | Rocky bash | HOWTO-Rocky-SDR-VM, PATCHNOTES | **PERMISSION CHANGE** - wheel = admin. Report to the operator and File Bot (USERPASS-SOP). |
| `lsusb` | Lists USB devices (RTL-SDR 0bda:2838, HackRF 1d50:6089). | Rocky bash | TROUBLESHOOT-Rotre | Read-only. |
| `rtl_test` | Tests the RTL-SDR: tuner found and samples lost (0 lost = good). | Rocky bash | HOWTO-Rocky-SDR-VM, KNOWN-ISSUES, TROUBLESHOOT-Rotre, README | Read-only. Ctrl+C to stop. |
| `rtl_test -t` | Quick RTL-SDR tuner check. | Rocky bash | TROUBLESHOOT-Rotre | Read-only. |
| `hackrf_info` | Detects a HackRF (runs fine with no board attached). | Rocky bash | TROUBLESHOOT-Rotre | Read-only. |
| `sdrpp --help` | SDR++ smoke test (returns 0 on a good ground image). | Rocky bash | TROUBLESHOOT-Rotre | Read-only. |
| `sdrpp --server --addr 127.0.0.1 --port 5259` | Runs SDR++ as a server so an SDR++ client can stream from this node. | Rocky bash | HOWTO-Rocky-SDR-VM, KNOWN-ISSUES, CHANGELOG, PATCHNOTES, TROUBLESHOOT-Rotre, private team doc | Ignores Ctrl+C (KI-16): stop with kill <pid>. Bind 127.0.0.1 unless the tailnet policy covers 5259. |
| `sudo ldconfig` | Refreshes the library cache after adding /etc/ld.so.conf.d/sdrpp-usr-local.conf (/usr/local/lib). | Rocky bash | HOWTO-Rocky-SDR-VM, PATCHNOTES | - |
| `rtl_433 -F mqtt://<hub>` | Decodes ISM-band sensors and publishes them to the hub's MQTT broker (first node-to-hub demo). | Rocky bash | private team doc | Lab broker is anonymous (KI-20) - lab mesh only. |
| `kill <pid>` | Stops a process by ID (SDR++ server, stray http.server). | Rocky bash | KNOWN-ISSUES | Check the PID first (ps / pgrep) - wrong PID kills the wrong thing. |

## Network

| Command | What it does (plain words) | Runs on | Used in | Caution |
|---|---|---|---|---|
| `meshctl profile <good/degraded/contested/cut/NAME> [core/gnd/hab/uas/all]` | On emu-01: applies a link-quality profile to one port or all (default all). | Rocky bash | NETWORK-SOP, TROUBLESHOOT-Rotre, README | Changes live shaping; cut drops all traffic on that port. |
| `meshctl profile good all` | Restores a clean mesh (first fix when the lab mesh looks broken). | Rocky bash | TROUBLESHOOT-Rotre, NETWORK-SOP | - |
| `meshctl status` | Shows bridge/port state, current profile per port and tc counters. | Rocky bash | NETWORK-SOP | Read-only. |
| `meshctl reset` | Removes all shaping (and IFBs). | Rocky bash | NETWORK-SOP | - |
| `meshctl list` | Lists profiles with descriptions. | Rocky bash | NETWORK-SOP | Read-only. |
| `meshctl boot` | Applies the default profile at boot (run by meshctl-default.service). | Rocky bash | NETWORK-SOP | - |
| `MESHCTL_DRY_RUN=1 meshctl profile degraded all` | Prints the tc commands a profile would run, without applying them. | Rocky bash | NETWORK-SOP, README | Read-only. |
| `tc qdisc del dev <port> root` | Removes shaping from one emu-01 port by hand. | Rocky bash | NETWORK-SOP | Prefer meshctl. Live change. |
| `tc qdisc add dev <port> root netem limit 100 delay 270ms 100ms loss gemodel 2.8% 25% 100% 0% reorder 1% rate 1mbit` | Manual contested-style netem on one port (delay, bursty Gilbert-Elliott loss, reorder, 1 Mbit cap). | Rocky bash | NETWORK-SOP | Prefer meshctl. Live change. |
| `tc qdisc replace ...` | Do not use for profile changes: it kept the old loss correlation; meshctl deletes and re-adds instead. | Rocky bash | NETWORK-SOP, PATCHNOTES, HOWTO-Rocky-SDR-VM | Known-bad method. |
| `ethtool -K <port> gro off gso off tso off` | Turns off offloads on mesh ports so netem shapes real packets (NM ethtool.feature-* does the same). | Rocky bash | NETWORK-SOP (implied) | Live change on that NIC. |
| `bridge fdb show br br-mesh` | Shows which MAC was learned on which mesh port. | Rocky bash | NETWORK-SOP | Read-only. |
| `sudo ./scripts/emu-01/emu-setup.sh [--apply]` | One-time emu-01 setup (bridge, ports by MAC, offloads, meshctl, boot unit). Dry run unless --apply; refuses unless hostname is emu-01. | Rocky bash | NETWORK-SOP, private team doc | --apply changes the VM's network. |
| `sudo ./scripts/hub-01/hub-setup.sh [--apply]` | One-time hub-01 setup (Mosquitto, dnsmasq, chrony, firewalld, netconfig). Dry run unless --apply. | Rocky bash | NETWORK-SOP, private team doc | --apply changes network, firewall and services. |
| `sudo lab-netconfig` | Re-applies node.conf now (hostname, mesh IP, hosts block, chrony). | Rocky bash | NETWORK-SOP | Live network change on the node. |
| `lab-netconfig --check [--config FILE]` | Validates a node.conf without applying it (the shared validator). | Rocky bash | NETWORK-SOP, private team doc | Read-only. |
| `lab-netconfig --dry-run` | Shows what it would change, applies nothing. | Rocky bash | private team doc | Read-only. |
| `systemctl status lab-netconfig` | Shows whether the boot-time network apply ran OK. | Rocky bash | NETWORK-SOP | Read-only. |
| `cat /etc/<node-dir>/effective.conf` | Shows the settings the node actually applied (STATE=applied). | Rocky bash | NETWORK-SOP, README, HOW-TO-Rotre-Flash | Read-only. |
| `nmcli -g GENERAL.CONNECTION device show <if>` | Shows which NetworkManager connection (mesh / mesh-fallback) a NIC is on. | Rocky bash | NETWORK-SOP | Read-only. |
| `nmcli connection modify <conn> ...` / `nmcli connection up <conn>` | Changes / activates a NetworkManager connection (what netconfig does on a manual re-run). | Rocky bash | NETWORK-SOP | Live network change - can drop your SSH session. |
| `nmcli --offline ...` | Renders NM keyfiles without NM running (used at boot by netconfig). | Rocky bash | NETWORK-SOP | Writes /etc/NetworkManager/system-connections/. |
| `hostnamectl` / `hostname` | Shows or sets the hostname. | Rocky bash | NETWORK-SOP | Setting it changes the node's name on the mesh. |
| `systemd-detect-virt` | Says whether the node runs in a VM (oracle = VirtualBox). | Rocky bash | NETWORK-SOP | Read-only. |
| `dig @10.X.0.10 hab-01.lab.internal +short` | Checks hub-01 DNS answers for a node name. | Rocky bash | NETWORK-SOP | Read-only. |
| `dig -x 10.X.20.21 @10.X.0.10` | Reverse DNS check on hub-01. | Rocky bash | NETWORK-SOP | Read-only. |
| `getent hosts hub-01` | Resolves a name the way the system does (works from the /etc/hosts block even when DNS is cut). | Rocky bash | NETWORK-SOP | Read-only. |
| `chronyc sources -v` | Shows time sources; hub-01 should be selected (*). | Rocky bash | NETWORK-SOP, private team doc | Read-only. |
| `chronyd -p` | Parses the chrony config and prints it (syntax check). | Rocky bash | private team doc | Read-only. |
| `ping -c 200 -i 0.2 hub-01` | 200 fast pings to measure loss and RTT under a profile. | Rocky bash | NETWORK-SOP | Read-only. |
| `iperf3 -c hub-01 -t 30 [-R]` | TCP throughput test to hub-01 (-R = reverse direction). | Rocky bash | NETWORK-SOP | Loads the link for 30 s. |
| `iperf3 -c hub-01 -u -b <0.9 x rate> -t 30 [-R]` | UDP throughput / loss test at 90% of the profile rate. | Rocky bash | NETWORK-SOP | Loads the link for 30 s. |
| `mosquitto_sub -h hub-01 -t 'lab/#' -v` | Watches every lab MQTT message on hub-01. | Rocky bash | NETWORK-SOP, KNOWN-ISSUES | Lab broker is anonymous (KI-20). Clients not in the ground image yet (KI-22). |
| `i=0; while :; do mosquitto_pub -h 10.X.0.10 -q 1 -t lab/hab/hab-01/status -m "{...seq $i...}"; i=$((i+1)); sleep 1; done` | Publishes a numbered test status message every second (MQTT loss/latency test). | Rocky bash | NETWORK-SOP, KNOWN-ISSUES | Runs until Ctrl+C. |
| `dnsmasq --test` | Checks the dnsmasq config syntax. | Rocky bash | NETWORK-SOP, README, private team doc | Read-only. |
| `journalctl -u dnsmasq` | Shows dnsmasq logs (e.g. DHCPACK for a node). | Rocky bash | NETWORK-SOP | Read-only. |
| `sudo firewall-cmd --set-default-zone=trusted` | Sets the guest firewall default zone to trusted (lab setting). | Rocky bash | HOWTO-Rocky-SDR-VM, PATCHNOTES | **FIREWALL CHANGE** - opens every port, incl. on tailscale0 (KI-7, KI-17). Revert before any release. |
| `New-NetFirewallRule -DisplayName "<name>" -Direction Inbound -Protocol TCP -LocalPort 21118 -RemoteAddress 100.64.0.0/10 -Action Allow` | Planned: allow RustDesk direct IP only from the tailnet range. | Windows PowerShell | private team doc (implied) | **FIREWALL CHANGE** - admin + operator approval; remove any broad RustDesk rules. |
| `Remove-NetFirewallRule -DisplayName "<temp-http-rule>"` | Pending cleanup of the temporary host HTTP rule. | Windows PowerShell | CHANGELOG, LAB-TODO (implied) | **FIREWALL CHANGE** - admin + approval. Removes only that named rule. |
| `python -m http.server 8765` | Temporary file-serving listener used once on the host; still pending cleanup (KI-5). | either | KNOWN-ISSUES, CHANGELOG, PATCHNOTES, LAB-TODO | **EXPOSURE** - serves the current folder to the network. Do not start; stop it if found (kill <pid>). |

## Git / publish

| Command | What it does (plain words) | Runs on | Used in | Caution |
|---|---|---|---|---|
| `./scripts/public-scrub-check.sh` | In a lab-portfolio clone: scans the whole public tree for forbidden patterns. Exit 0 = PASS. | Rocky bash | PUBLIC-SCRUB-GATE, BOT-SOP, FILING-SOP | Mandatory before any public push. Fail = no push. |
| `./scripts/public-scrub-check.sh <file> [<file>...]` | Scans only the listed public export files (works from either repo). | Rocky bash | PUBLIC-SCRUB-GATE | - |
| `./scripts/public-scrub-check.sh --staged` | Scans git-staged files. | Rocky bash | PUBLIC-SCRUB-GATE | - |
| `./scripts/public-scrub-check.sh --range origin/main..HEAD` | Scans files changed in the commits about to be pushed. | Rocky bash | PUBLIC-SCRUB-GATE | - |
| `.\scripts\public-scrub-check.ps1 [-Staged / -Range <A..B> / <files>]` | Windows version of the scrub gate. | Windows PowerShell | PUBLIC-SCRUB-GATE | Same rule: fail = no push. |
| `cp scripts/hooks/pre-push-public-scrub .git/hooks/pre-push && chmod +x .git/hooks/pre-push` | Installs the pre-push hook so a lab-portfolio push is refused on any scrub hit. | Rocky bash | PUBLIC-SCRUB-GATE, BOT-SOP | - |
| `python3 scripts/make-public-sop.py` | Regenerates the public NETWORK-SOP and fails if any scrub term survives. | Rocky bash | private team doc, PATCHNOTES, README | - |
| `bash -n <script>` | Syntax-checks a bash script without running it. | Rocky bash | private team doc, README | Read-only. |
| `shellcheck -S warning <script>` | Lints a bash script (warnings and up). | Rocky bash | private team doc | Read-only. |
| `git push` | Normal push of committed doc changes (private cyberdeck, or lab-portfolio after the gate passes). | either | README (publish habit, implied) | lab-portfolio: scrub gate PASS first. |
| `git push --force` | Overwrites remote history. | either | BOT-SOP, PUBLIC-SCRUB-GATE | **DESTRUCTIVE / FORBIDDEN** on private cyberdeck. Public lab-portfolio only with Ghost Lead + operator authorization. |

## Files / backup

| Command | What it does (plain words) | Runs on | Used in | Caution |
|---|---|---|---|---|
| `robocopy <src> <dst> /E /COPY:DAT /R:1 /W:1` | Copies a folder tree (with subfolders, data/attributes/timestamps; 1 retry) to the second local copy or the USB kit. Then hash-verify. | Windows PowerShell | FILING-SOP, private team doc, CHANGELOG | Never add /MIR or /PURGE (they delete files at the destination). Never target OneDrive. |
| `Move-Item <path> Archive\YYYY-MM-DD\<bucket>\` | Archives a superseded doc / installer / snapshot / OVA instead of deleting it; log the move in CHANGELOG. | Windows PowerShell | FILING-SOP, PATCHNOTES, README | Check the destination does not already hold a same-name file. |
| `Remove-Item -Recurse -Force <path>` | Deletes a folder tree. Not used by any filing step - listed for the warning. | Windows PowerShell | FILING-SOP (archive, never delete) | **DESTRUCTIVE** - never for filing; archive instead. Any delete needs approval. |
| `[System.IO.File]::ReadAllText(<path>,[Text.Encoding]::UTF8)` / `[System.IO.File]::WriteAllText(<path>, <text>, (New-Object System.Text.UTF8Encoding $false))` | The only approved way to read/write doc text in PowerShell 5 (UTF-8, no BOM). Get-Content -Raw / Set-Content cause mojibake. | Windows PowerShell | team rule | WriteAllText overwrites the file - keep the original until checked. |

## Other

| Command | What it does (plain words) | Runs on | Used in | Caution |
|---|---|---|---|---|
| `pipeline/release-hardening.sh` | Pre-release hardening: removes lab NOPASSWD sudo, autologin, trusted firewall zone etc. Not run yet; required before any non-lab use. | Rocky bash | HOWTO-Rocky-SDR-VM, KNOWN-ISSUES, LAB-TODO, TROUBLESHOOT-Rotre, HOW-TO-Rotre-From-Scratch | Changes accounts, sudo and firewall on the target - run only on an approved image; operator + Ghost Lead approval. |
| `powercfg /h off` | Turns off hibernation (and Fast Startup) on the PC so remote access survives restarts. | Windows PowerShell | private team doc | Admin; system power setting. |
| `sudo dnf update` | Updates all packages on a Rocky box (planned mirror VM). | Rocky bash | private team doc | Snapshot first on lab VMs; can change kernel / drivers. |

---
*Maintained by File Bot. Standing rule: every newly documented command is added here.*
